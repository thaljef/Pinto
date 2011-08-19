package Pinto;

# ABSTRACT: Perl distribution repository manager

use Moose;

use Carp;
use Class::Load;
use Path::Class;

use Pinto::ActionFactory;
use Pinto::ActionBatch;
use Pinto::IndexManager;

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------
# Moose attributes

# TODO: make private
has action_factory => (
    is        => 'ro',
    isa       => 'Pinto::ActionFactory',
    builder   => '_build_action_factory',
    handles   => [ qw(create_action) ],
    lazy      => 1,
);

#------------------------------------------------------------------------------

# TODO: make private
has action_batch => (
    is         => 'ro',
    isa        => 'Pinto::ActionBatch',
    builder    => '_build_action_batch',
    handles    => [ qw(enqueue run) ],
    lazy       => 1,
);

#------------------------------------------------------------------------------

# TODO: make private
has idxmgr => (
    is       => 'ro',
    isa      => 'Pinto::IndexManager',
    builder  => '_build_idxmgr',
    lazy     => 1,
);

#------------------------------------------------------------------------------

# TODO: make private
has store => (
    is       => 'ro',
    isa      => 'Pinto::Store',
    builder  => '_build_store',
    lazy     => 1,
);

#------------------------------------------------------------------------------
# Moose roles

with qw( Pinto::Role::Configurable
         Pinto::Role::Loggable );

with qw( Pinto::Role::UserAgent );

#------------------------------------------------------------------------------
# Builders

sub _build_action_factory {
    my ($self) = @_;

    return Pinto::ActionFactory->new( config => $self->config(),
                                      logger => $self->logger(),
                                      idxmgr => $self->idxmgr(),
                                      store  => $self->store() );
}

sub _build_action_batch {
    my ($self) = @_;

    return Pinto::ActionBatch->new( config => $self->config(),
                                    logger => $self->logger(),
                                    idxmgr => $self->idxmgr(),
                                    store  => $self->store() );
}

sub _build_idxmgr {
    my ($self) = @_;

    return Pinto::IndexManager->new( config => $self->config(),
                                     logger => $self->logger() );
}

sub _build_store {
    my ($self) = @_;

    my $store_class = $self->config->store();
    Class::Load::load_class( $store_class );

    return $store_class->new( config => $self->config(),
                              logger => $self->logger() );
}

#------------------------------------------------------------------------------
# Public methods


=method create()

Creates a new empty repository.

=cut

sub create {
    my ($self) = @_;

    # HACK...I want to do this before checking out from VCS
    my $repos = $self->config()->repos();
    croak "A repository already exists at $repos"
        if -e file($repos, qw(modules 02packages.details.txt.gz));

    $self->enqueue( $self->create_action('Create') );
    $self->run();

    return $self;
}

#------------------------------------------------------------------------------

=method mirror()

Populates your repository with the latest version of all distributions
found in the foreign repository (which is usually a CPAN mirror).  Your
locally added distributions will always mask those mirrored from the
remote repository.

=cut

sub mirror {
    my ($self) = @_;

    $self->enqueue( $self->create_action('Mirror') );
    $self->run();

    return $self;
}

#------------------------------------------------------------------------------

=method add(dists => ['YourDist.tar.gz'], author => 'SOMEONE')

=cut

sub add {
    my ($self, %args) = @_;

    my $dists = delete $args{dists};
    $dists = [$dists] if ref $dists ne 'ARRAY';

    for my $dist ( @{$dists} ) {

        # TODO: fetching remote dists should be done by the action,
        # so that exceptions are trapped.  Must allow dist parameter
        # to be a String, File or URL, and then do the right thing!

        $dist = $self->_dist_from_url($dist) if _is_url($dist);
        $self->enqueue( $self->create_action('Add', dist => $dist, %args) );
    }

    $self->run();

    return $self;
}

#------------------------------------------------------------------------------

=method remove(packages => ['Some::Package'], author => 'SOMEONE')

=cut

sub remove {
    my ($self, %args) = @_;

    my $packages = delete $args{packages};
    $packages = [$packages] if ref $packages ne 'ARRAY';

    for my $pkg ( @{$packages} ) {
        $self->enqueue( $self->create_action('Remove', package => $pkg, %args) );
    }

    $self->run();

    return $self;
}

#------------------------------------------------------------------------------

=method clean()

=cut

sub clean {
    my ($self) = @_;

    $self->enqueue( $self->create_action('Clean') );
    $self->run();

    return $self;
}

#------------------------------------------------------------------------------

=method list()

=cut

sub list {
    my ($self, %args) = @_;

    $self->enqueue( $self->create_action('List', %args) );
    $self->run();

    return $self;
}

#------------------------------------------------------------------------------

=method verify()

=cut

sub verify {
    my ($self, %args) = @_;

    $self->enqueue( $self->create_action('Verify') );
    $self->run();

    return $self;
}

#------------------------------------------------------------------------------

sub _is_url {
    my ($string) = @_;

    return $string =~ m/^ (?: http|ftp|file|) : /x;
}

#------------------------------------------------------------------------------

sub _dist_from_url {
    my ($self, $dist) = @_;

    my $url = URI->new($dist)->canonical();
    my $path = Path::Class::file( $url->path() );
    return $path if $url->scheme() eq 'file';

    my $base     = $path->basename();
    my $tempdir  = File::Temp::tempdir(CLEANUP => 1);
    my $tempfile = Path::Class::file($tempdir, $base);

    $self->fetch(url => $url, to => $tempfile);

    return Path::Class::file($tempfile);
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#-----------------------------------------------------------------------------

1;

__END__

=pod

=head1 SYNOPSIS

You probably want to look at the documentation for L<pinto-admin>.
All the modules in this distribution are private (for now).  So the
API documentation is purely for my own reference.  But this document
does explain what Pinto does and why it exists, so feel free to read
on anyway.

=head1 DISCUSSION

L<Pinto> is a set of tools for creating and managing a CPAN-style
repository.  This repository can contain just your own private
distributions, or you can fill it with the latest ones from a CPAN
mirror, or both.  You can then use your favorite CPAN client to
fetch distributions from your repository and install them as you
normally would.

L<Pinto> shares a lot of DNA with L<CPAN::Site>, L<CPAN::Mini>, and
L<CPAN::Mini::Inject>.  But I wasn't entirely satisfied with those, so
I built a (hopefully better) mousetrap.

L<Pinto> is B<not> magic pixie dust though.  It does not guarantee
that you will always have a working stack of distributions.  It is
still up to you to figure out what to put in your repository.
L<Pinto> just gives you a set of tools for doing that in a controlled
manner.

This is a work in progress.  Comments, criticisms, and suggestions
are always welcome.  Feel free to contact C<thaljef@cpan.org>.

=head1 WHY IS IT CALLED "Pinto"

The term "CPAN" is heavily overloaded.  In some contexts, it means the
L<CPAN> module or the L<cpan> utility.  In other contexts, it means a
mirror like L<http://cpan.perl.org> or a web site like
L<http://search.cpan.org>.

I wanted to avoid all that confusion, so I picked a name that has no
connection to "CPAN" at all.  "Pinto" is a nickname that I sometimes
call my son, Wesley.

=head1 THANKS

=for stopwords Genentech Hartzell Walde Sorichetti PASSed

=over 4

=item Randal Schwartz - for pioneering the first mini CPAN back in 2002

=item Ricardo Signes - for creating CPAN::Mini, which inspired much of Pinto

=item Shawn Sorichetti & Christian Walde - for creating CPAN::Mini::Inject

=item George Hartzell @ Genentech - for sponsoring this project

=back

=cut
