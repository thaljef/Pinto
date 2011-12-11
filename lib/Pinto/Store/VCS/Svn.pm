package Pinto::Store::VCS::Svn;

# ABSTRACT: Store your Pinto repository with Subversion

use Moose;

use DateTime;
use Pinto::Util::Svn;
use Pinto::Types qw(Uri);

use namespace::autoclean;

#-------------------------------------------------------------------------------

# VERSION

#-------------------------------------------------------------------------------
# ISA

extends qw( Pinto::Store::VCS );

#-------------------------------------------------------------------------------
# Attributes

has svn_location => (
    is       => 'ro',
    isa      => Uri,
    init_arg => undef,
    default  => sub { Pinto::Util::Svn::location( path => $_[0]->config->root_dir() ) },
    coerce   => 1,
    lazy     => 1,
);


#-------------------------------------------------------------------------------
# Methods

augment initialize => sub {
    my ($self) = @_;

    my $root_dir = $self->config->root_dir();
    Pinto::Util::Svn::svn_update(dir => $root_dir);

    return $self;
};

#-------------------------------------------------------------------------------

augment add_path => sub {
    my ($self, %args) = @_;

    my $added = Pinto::Util::Svn::svn_add(path => $args{path});
    $self->mark_path_for_commit($added);

    return $self;
};

#-------------------------------------------------------------------------------

augment remove_path => sub {
    my ($self, %args) = @_;


    my $removed = Pinto::Util::Svn::svn_remove(path => $args{path});
    $self->mark_path_for_commit($removed);

    return $self;
};

#-------------------------------------------------------------------------------

augment commit => sub {
    my ($self, %args) = @_;

    my $message = $args{message} || 'NO MESSAGE WAS GIVEN';
    my $paths   = $self->paths_to_commit();

    Pinto::Util::Svn::svn_commit(paths => $paths, message => $message);

    return $self;
};

#-------------------------------------------------------------------------------
# TODO: allow users to specify a tag template.

augment tag => sub {
    my ($self, %args) = @_;

    my $now    = DateTime->now();
    my $tag    = $now->strftime( $args{tag} );
    my $msg    = $args{mmessage};
    my $origin = $self->svn_location();

    $self->info("Tagging at $tag");

    Pinto::Util::Svn::svn_tag(from => $origin, to => $tag, message => $msg);

    return $self;
};

#-------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#-------------------------------------------------------------------------------

1;

__END__

=head1 SYNOPSIS

  # If you don't already have a Pinto repository, create one (notice the --store option here)
  $> pinto-admin --repos=~/tmp/PINTO create --store=Pinto::Store::VCS::Svn

  # If you do already have a repository, edit its config (at $REPOS/.pinto/config/pinto.ini)
  store = Pinto::Store::VCS::Svn

  # Import Pinto repository into Subversion
  $> svn import ~/tmp/PINTO http://my.company.com/svn/trunk/PINTO -m 'Import new Pinto repos'

  # Checkout working copy of the Pinto repository
  $> svn co http://my.company.com/svn/trunk/PINTO ~/srv/PINTO

  # You may now destroy the old non-versioned Pinto repository
  $> rm -rf ~/tmp/PINTO

Now run L<pinto-admin> or L<pinto-server> as you normally would,
setting the C<--repos> to the path of the working copy (which would be
F<~/srv/PINTO> in the example above).

=head1 DESCRIPTION

L<Pinto::Store::VCS::Svn> is a back-end for L<Pinto> that stores the
repository inside Subversion.  Before you can effectively use this
Store, you must first place your Pinto repository somewhere in
Subversion (see L</"SYNOPSIS"> for the typical procedure).

=head1 CAVEATS

=over 4

=item The C<svn> program is required.

At present, you must have the binary C<svn> client installed somewhere
in your C<$PATH> for this Store to work.  In future versions, we may
try using L<SVN::Client> or some other interface.

=item No built-in support for authentication.

All authentication is handled by the C<svn> client.  So you must have
the credentials for your repository already cached.  If you cannot or
will not allow C<svn> to cache your credentials, then this module will
not work.

=item Subversion does not accurately manage time stamps.

This may fool L<Pinto> into making an inaccurate mirror because it
thinks your local copy is newer than the mirror. As long as
you don't throw away your working copy, you shouldn't run into this
problem.  But I have a workaround planned for a future release.

=back

=cut
