package Pinto::Store::Svn;

# ABSTRACT: Store your Pinto repository with Subversion

use Moose;

use Pinto::Util::Svn;
use Date::Format qw(time2str);

extends 'Pinto::Store';

#-------------------------------------------------------------------------------

# VERSION

#-------------------------------------------------------------------------------

sub initialize {
    my ($self, %args) = @_;

    my $local = $args{local} || $self->config()->get_required('local');
    my $trunk_url = $args{svn_trunk_url} || $self->config()->get_required('svn_trunk_url');

    $self->logger()->log("Checking out (or updating) working copy ... ", {nolf => 1});
    Pinto::Util::Svn::svn_checkout(url => $trunk_url, to => $local);
    $self->logger()->log('DONE');

    return 1;
}

#-------------------------------------------------------------------------------

sub finalize {
    my ($self, %args) = @_;

    my $message   = $args{message} || 'NO MESSAGE WAS GIVEN';
    my $local     = $self->config()->get_required('local');

    $self->logger()->log("Scheduling files for addition/deletion ... ", {nolf => 1});
    Pinto::Util::Svn::svn_schedule(path => $local);
    $self->logger()->log('DONE');


    $self->logger()->log("Committing changes ... ", {nolf => 1});
    Pinto::Util::Svn::svn_commit(paths => $local, message => $message);
    $self->logger()->log('DONE');

    $self->_make_tag() if $self->config()->get('svn_tag_url');

    return 1;
}

#-------------------------------------------------------------------------------

sub _make_tag {
    my ($self) = @_;

    my $now = time;

    my $trunk_url    = $self->config()->get_required('svn_trunk_url');
    my $tag_template = $self->config()->get_required('svn_tag_url');
    my $tag_url      = time2str($tag_template, $now);

    my $as_of = time2str('%C', $now);
    my $message  = "Tagging Pinto repository as of $as_of.";

    $self->logger()->log("Tagging ... ", {nolf => 1});
    Pinto::Util::Svn::svn_tag(from => $trunk_url, to => $tag_url, message => $message);
    $self->logger()->log('DONE');

    return 1;
}
#-------------------------------------------------------------------------------

1;

__END__

=head1 SYNOPSIS

Add this to your Pinto configuration (usually in F<~/.pinto/config.ini>):

  store_class   = Pinto::Store::Svn
  svn_trunk_url = http://my-repository/trunk/PINTO
  svn_tag_url   = http://my-repository/tags/PINTO-%Y%m%d.%H%M%S

And then run L<pinto> as you normally would.

=head1 DESCRIPTION

L<Pinto::Store::Svn> is a back-end for L<Pinto> that stores the
repository inside Subversion.

=head1 CONFIGURATION

These configuration parameters are in addition to those provided by
L<Pinto>.  All configuration parameters should go in your L<pinto>
config file, which is usually located in F<~/.pinto/config.ini>.

=over 4

=item svn_trunk_url

(Required) The URL to the location in Subversion where you want the
trunk (i.e. mainline) branch of your Pinto repository.  If this
location does not exist, it will be created for you.  Each time you
run L<pinto>, the changes to your repository will be committed to this
branch.

=item svn_tag_url

(Optional) The URL of the location in your Subversion repository where
you want to create a tag of the CPAN mirror.  When L<pinto> commits
changes to the C<svn_trunk_url>, that URL will be tagged (i.e. copied)
to the C<svn_tag_url>. If you do not specify C<svn_tag_url> then no
tag is made.

In most situations, you'll want to keep multiple tags that represent
the state of CPAN at a various points in time.  So the typical
practice is to put a datestamp in the name of your tag.  To make this
easy and customizable, you can embed any of the L<Date::Format>
conversion specifications in your URL.

For example, if you had this in your F<~/.pinto/config.ini>:

 svn_tag_url: http://my-company/svn/tags/PINTO-%y.%m.%d

and ran C<pinto mirror> on June 17, 2011, then it would produce a tag at this URL:

 http://my-company/svn/tags/PINTO-11.06.17

Be sure to choose a datestamp with sufficient resolution for your
needs.  If you are only going to run L<pinto> once a month, then
you probably only need a year and month to distinguish your tag.  But
if you are going to run it several times a day, then you'll need day,
hours and minutes (and possibly seconds) too.

And if you don't put any datestamp in your C<svn_tag_url> at all, then
you're basically limited to running L<pinto> only once, because you
can't make the same tag more than once (unless you remove the previous
tag by some other means).

=back

=head1 CAVEATS

=over 4

=item C<svn> client is required.

At present, you must have the binary C<svn> client installed somwhere
in your C<$PATH> for this module to work.  In future versions, we may
try using L<SVN::Client> or some other interface.

=item No built-in support for authentication.

All authentication is handled by the C<svn> client.  So you must have
the credentials for your repository already cached.  If you cannot or
will not allow C<svn> to cache your credentials, then this module will
not work.

=item Subversion does not accurately manage timestamps.

This may fool L<Pinto> into making an inaccurate mirror because it
thinks your local copy is newer than the mirror. As long as
you don't throw away your working copy, you shouldn't run into this
problem.  But I have a workaround planned for a future release.

=back

=cut
