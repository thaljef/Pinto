package Pinto;

# ABSTRACT: Perl archive repository manager

use Moose;

use Carp;
use Path::Class;
use Class::Load;

use Pinto::Util;
use Pinto::ActionFactory;
use Pinto::ActionBatch;

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------
# Moose attributes

has action_factory => (
    is        => 'ro',
    isa       => 'Pinto::ActionFactory',
    builder   => '__build_action_factory',
    handles   => [ qw(create_action) ],
    lazy      => 1,
);

#------------------------------------------------------------------------------

has action_batch => (
    is         => 'ro',
    isa        => 'Pinto::ActionBatch',
    builder    => '__build_action_batch',
    handles    => [ qw(enqueue run) ],
    lazy       => 1,
);

#------------------------------------------------------------------------------

has idxmgr => (
    is       => 'ro',
    isa      => 'Pinto::IndexManager',
    builder  => '__build_idxmgr',
    init_arg => undef,
    lazy     => 1,
);

#------------------------------------------------------------------------------
# Moose roles

with qw(Pinto::Role::Configurable Pinto::Role::Loggable);


#------------------------------------------------------------------------------
# Builders

sub __build_action_factory {
    my ($self) = @_;

    return Pinto::ActionFactory->new( config => $self->config(),
                                      logger => $self->logger(),
                                      idxmgr => $self->idxmgr() );
}

sub __build_action_batch {
    my ($self) = @_;

    return Pinto::ActionBatch->new( config => $self->config(),
                                    logger => $self->logger(),
                                    idxmgr => $self->idxmgr() );
}

sub __build_idxmgr {
    my ($self) = @_;

    return Pinto::IndexManager->new( config => $self->config(),
                                     logger => $self->logger() );
}

#------------------------------------------------------------------------------
# Private methods

sub _should_cleanup {
    my ($self) = @_;
    return not $self->config->nocleanup();
}

#------------------------------------------------------------------------------
# Public methods


=method create()

Creates a new empty repository.

=cut

sub create {
    my ($self) = @_;

    # HACK...I want to do this before checking out from VCS
    my $local = Path::Class::dir( $self->config()->local() );
    die "Looks like you already have a repository at $local\n"
        if -e file($local, qw(modules 02packages.details.txt.gz));

    $self->enqueue( $self->create_action('Create') );
    $self->run();

    return $self;
}

#------------------------------------------------------------------------------

=method mirror()

Populates your repository with the latest version of all packages
found on the CPAN mirror.  Your locally added packages will always
mask those pulled from the mirror.

=cut

sub mirror {
    my ($self) = @_;

    $self->enqueue( $self->create_action('Mirror') );
    $self->enqueue( $self->create_action('Clean') ) if $self->_should_cleanup();
    $self->run();

    return $self;
}

#------------------------------------------------------------------------------

=method add(file => 'YourDist.tar.gz', author => 'SOMEONE')

=cut

sub add {
    my ($self, %args) = @_;

    $self->enqueue( $self->create_action('Add', %args) );
    $self->enqueue( $self->create_action('Clean') ) if $self->_should_cleanup();
    $self->run();

    return $self;
}

#------------------------------------------------------------------------------

=method remove(package => 'Some::Package', author => 'SOMEONE')

=cut

sub remove {
    my ($self, %args) = @_;

    $self->enqueue( $self->create_action('Remove', %args) );
    $self->enqueue( $self->create_action('Clean') ) if $self->_should_cleanup();
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
    my ($self) = @_;

    $self->enqueue( $self->create_action('List') );
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

__PACKAGE__->meta->make_immutable();

#-----------------------------------------------------------------------------
1;

__END__

=pod

=head1 DESCRIPTION

You probably want to look at the documentation for L<pinto>.  This is
a private module (for now) and the interface is subject to change.  So
the API documentation is purely for my own reference.  But this
document does explain what Pinto does and why it exists, so feel free
to read on anyway.

This is a work in progress.  Comments, criticisms, and suggestions
are always welcome.  Feel free to contact C<thaljef@cpan.org>.

=head1 TERMINOLOGY

Some of the terms around CPAN are frequently misused.  So for the
purpose of this document, I am going to define some terms.  I am not
saying that these are necessarily the "correct" definitions, but
this is what I mean when I use them.

=over 4

=item package

A "package" is the name that appears in a C<package> statement.  This
is what PAUSE indexes, and this is what you usually ask L<cpan> or
L<cpanm> to install for you.

=item module

A "module" is the name that appears in a C<use> or (sometimes)
C<require> statement, and it always corresponds to a physical file
somewhere.  A module usually contains only one package, and the name
of the module usually matches the name of the package.  But sometimes,
a module may contain many packages with completely arbitrary names.

=item archive

An "archive" is a collection of Perl modules that have been packaged
in a particular structure.  This is what you get when you run C<"make
dist"> or C<"./Build dist">.  Archives may come from a "mirror",
or you may create your own. An archive is the "A" in "CPAN".

=item repository

A "repository" is a collection of archives that are organized in a
particular structure, and having an index describing which packages
are contained in each archive.  This is where L<cpan> and L<cpanm>
get the packages from.

=item mirror

A "mirror" is a copy of a public CPAN repository
(e.g. http://cpan.perl.org).  Every "mirror" is a "repository", but
not every "repository" is a "mirror".

=back

=head1 RULES

There are certain rules that govern how the indexes are managed.
These rules are intended to ensure that folks pulling packages from
your repository will always get the *right* packages (according to my
definitionof "right").  Also, the rules attempt to make Pinto behave
somewhat like PAUSE does.

=over 4

=item A local package always masks a mirrored package, and all other
packages that are in the same archive with the mirrored package.

This rule is key, so pay attention.  If the CPAN mirror has an archive
that contains both C<Foo> and C<Bar> packages, and you add your own
archive that contains C<Foo> package, then both the C<Foo> and C<Bar>
mirroed packages will be removed from your index.  This ensures that
anyone pulling packages from your repository will always get *your*
version of C<Foo>.  But as a result, they'll never be able to get
C<Bar>.

=item You can never add an archive with the same name twice.

Most archive-building tools will put some kind of version number in
the name of the archive, so this is rarely a problem.

=item Only the original author of a local package can add a newer
version of it.

Ownership is given on a first-come basis, just like PAUSE.  So if
C<SALLY> is the first author to add local package C<Foo::Bar> to the
repository, then only C<SALLY> can ever add that package again.

=item Only the original author of a local package can remove it.

Just like when adding new versions of a local package, only the
original author can remove it.

=back

=head1 WHY IS IT CALLED "Pinto"

The term "CPAN" is heavily overloaded.  In some contexts, it means the
L<CPAN> module or the L<cpan> utility.  In other contexts, it means a
mirror like L<http://cpan.perl.org> or a site like
L<http://search.cpan.org>.

I wanted to avoid confusion, so I picked a name that has no connection
to "CPAN" at all.  "Pinto" is a nickname that I sometimes call my son,
Wesley.

=head1 TODO

=over 4

=item Enable plugins for visiting and filtering

=item Implement Pinto::Store::Git

=item Fix my Moose abuses

=item Consider storing indexes in a DB, instead of files

=item Automatically fetch dependecies when adding *VERY COOL*

=item New command for listing conflicts between local and mirrored index

=item Make file/directory permissions configurable

=item Refine terminology: consider "distribution" instead of "archive"

=item Need more error checking and logging

=item Lots of tests to write

=back

=head1 THANKS

=over 4

=item Randal Schwartz - for pioneering the first mini CPAN back in 2002

=item Ricardo Signes - for creating CPAN::Mini, which inspired much of Pinto

=item Shawn Sorichetti & Christian Walde - for creating CPAN::Mini::Inject

=back

=cut
