package Pinto::Store::VCS::Svn;

# ABSTRACT: Store your Pinto repository with Subversion

use Moose;

use Pinto::Util::Svn;
use Pinto::Types qw(URI);
use Date::Format qw(time2str);

extends 'Pinto::Store::VCS';

use namespace::autoclean;

#-------------------------------------------------------------------------------

# VERSION

#-------------------------------------------------------------------------------

has svn_location => (
    is       => 'ro',
    isa      => URI,
    init_arg => undef,
    default  => sub { Pinto::Util::Svn::location( path => $_[0]->config->repos() ) },
    coerce   => 1,
    lazy     => 1,
);


#-------------------------------------------------------------------------------

override initialize => sub {
    my ($self) = @_;

    my $repos = $self->config->repos();
    $self->logger->info('Updating working copy');
    Pinto::Util::Svn::svn_update(dir => $repos);

    return 1;
};

#-------------------------------------------------------------------------------

override add => sub {
    my ($self, %args) = @_;

    # Were going to let the superclass validate the arguments and copy
    # the file into place for us (if needed).
    super();

    # Now search the path backwards until we find the first parent
    # directory that is an svn working copy.  The directory or file
    # that is immediately below that directory is the one we should
    # schedule for addition.  Subversion will recursively add any
    # directories and files below that point for us.

    my $path = $args{file};
    my $original_path = $path;

    while (not -e $path->parent->file('.svn') ) {
        $path = $path->parent();
    }

    $self->logger->info("Scheduling $original_path for addition");
    Pinto::Util::Svn::svn_add(path => $path);
    $self->mark_path_as_added($path);

    return $self;
};

#-------------------------------------------------------------------------------

override remove => sub {
    my ($self, %args) = @_;

    my $file  = $args{file};
    return $self if not -e $file;

    $self->logger->info("Scheduling $file for removal");
    my $removed = Pinto::Util::Svn::svn_remove(path => $file);
    $self->mark_path_as_removed($removed);

    return $self;
};

#-------------------------------------------------------------------------------

override commit => sub {
    my ($self, %args) = @_;
    super();

    my $message   = $args{message} || 'NO MESSAGE WAS GIVEN';

    my $paths = [ $self->added_paths(),
                  $self->removed_paths(),
                  $self->modified_paths() ];

    $self->logger->info("Committing changes");
    Pinto::Util::Svn::svn_commit(paths => $paths, message => $message);

    return 1;
};

#-------------------------------------------------------------------------------

override tag => sub {
    my ($self, %args) = @_;

    my $now = time;

    my $origin = $self->svn_location();
    my $tag    = time2str( $args{tag}, $now );

    my $as_of   = time2str('%C', $now);
    my $message = "Tagging Pinto repository as of $as_of.";

    $self->logger->info("Making tag");
    Pinto::Util::Svn::svn_tag(from => $origin, to => $tag, message => $message);

    return 1;
};

#-------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#-------------------------------------------------------------------------------

1;

__END__

=head1 SYNOPSIS

  # Create Pinto a repository if you don't already have one
  $> pinto-admin --repos=~/tmp/PINTO create

  # Edit Pinto configuration ay ~/tmp/PINTO/config/pinto.ini
  store = Pinto::Store::VCS::Svn

  # Import Pinto repository into Subversion
  $> svn import ~/tmp/PINTO http://my.company.com/svn/trunk/PINTO

  # Checkout working copy of the Pinto repository
  $> svn co http://my.company.com/svn/trunk/PINTO ~/srv/PINTO

  # You may now destroy the old non-versioned Pinto repository
  $> rm -rf ~/tmp/PINTO

Now run L<pinto-admin> or L<pinto-server> as you normally would,
setting the C<--repos> to the path of the working copy (which would be
F<~/srv/PINTO> in the example above).

=head1 DESCRIPTION

L<Pinto::Store::VCS::Svn> is a back-end for L<Pinto> that stores the
repository inside Subversion.  Before configuring Pinto to use this
Store, you must first create a location within Subversion for L<Pinto>
to use (see L</"SYNOPSIS"> above).

=head1 CAVEATS

=over 4

=item The C<svn> program is required.

At present, you must have the binary C<svn> client installed somewhere
in your C<$PATH> for this module to work.  In future versions, we may
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
