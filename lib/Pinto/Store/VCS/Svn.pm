package Pinto::Store::VCS::Svn;

# ABSTRACT: Store your Pinto repository with Subversion

use Moose;

use Pinto::Util::Svn;
use Date::Format qw(time2str);

extends 'Pinto::Store::VCS';

use namespace::autoclean;

#-------------------------------------------------------------------------------

# VERSION

#-------------------------------------------------------------------------------

override initialize => sub {
    my ($self) = @_;

    my $repos = $self->config->repos();
    my $trunk = $self->config->svn_trunk();

    $self->logger->info("Checking out (or updating) working copy");
    Pinto::Util::Svn::svn_checkout(url => $trunk, to => $repos);

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

    my $trunk = $self->config->svn_trunk();
    my $tag   = time2str( ($args{tag} || $self->config->svn_tag()), $now );

    my $as_of = time2str('%C', $now);
    my $message  = "Tagging Pinto repository as of $as_of.";

    $self->logger->info("Making tag");
    Pinto::Util::Svn::svn_tag(from => $trunk, to => $tag, message => $message);

    return 1;
};

#-------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#-------------------------------------------------------------------------------

1;

__END__

=head1 SYNOPSIS

Add this to your Pinto configuration (usually in F<~/.pinto/config.ini>):

  ; other global params up here...

  store   = Pinto::Store::VCS::Svn

  [Pinto::Store::VCS::Svn]

  ; Required.  URL of repository location where the mainline version will live
  trunk = http://my-repository/trunk/PINTO

  ; Optional.  URL of location where trunk will be copied
  tag   = http://my-repository/tags/PINTO-%Y%m%d.%H%M%S

And then run L<pinto> as you normally would.

=head1 DESCRIPTION

L<Pinto::Store::VCS::Svn> is a back-end for L<Pinto> that stores the
repository inside Subversion.

=head1 CONFIGURATION

These configuration parameters are in addition to those provided by
L<Pinto>.  All configuration parameters should go in your L<pinto>
config file, which is usually located in F<~/.pinto/config.ini>.

=over 4

=item trunk

(Required) The URL to the location in Subversion where you want the
trunk (i.e. mainline) branch of your Pinto repository.  If this
location does not exist, it will be created for you.  Each time you
run L<pinto>, the changes to your repository will be committed to this
branch.

=item tag

(Optional) The URL of the location in your Subversion repository where
you want to create a tag of the CPAN mirror.  When L<pinto> commits
changes to the C<trunk>, that URL will be tagged (i.e. copied)
to the C<tag>. If you do not specify C<tag> then no
tag is made.

In most situations, you'll want to keep multiple tags that represent
the state of CPAN at a various points in time.  The typical practice
is to put a date stamp in the name of your tag.  Therefore, you can
embed any of the L<Date::Format> conversion specifications in your
URL and they will be expanded when the tag is constructed.

For example, if you had this in your F<~/.pinto/config.ini>:

 tag = http://my-company/svn/tags/PINTO-%y.%m.%d

and ran C<pinto mirror> on June 17, 2011, then it would produce a tag
at this URL:

 http://my-company/svn/tags/PINTO-11.06.17

Be sure to choose a date stamp with sufficient resolution for your
needs.  If you are only going to run L<pinto> once a month, then you
probably only need a year and month to distinguish your tag.  But if
you are going to run it several times a day, then you'll need day,
hours and minutes (and possibly seconds) too.

And if you don't put any date stamp in your C<tag> at all, then you're
basically limited to running L<pinto> only once, because you can't
make the same tag more than once (unless you remove the previous tag
by some other means).

=back

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
