# ABSTRACT: Add a local distribution into the repository

package Pinto::Action::Add;

use Moose;
use MooseX::Types::Moose qw(Bool Str);

use Pinto::Types qw(AuthorID ArrayRefOfFiles);
use Pinto::Exception qw(throw);

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

extends qw( Pinto::Action );

#------------------------------------------------------------------------------

with qw( Pinto::Role::PackageImporter );

#------------------------------------------------------------------------------

has author => (
    is         => 'ro',
    isa        => AuthorID,
    builder    => '_build_author',
    coerce     => 1,
    lazy       => 1,
);


has archives  => (
    isa       => ArrayRefOfFiles,
    traits    => [ qw(Array) ],
    handles   => {archives => 'elements'},
    required  => 1,
    coerce    => 1,
);


has stack => (
    is       => 'ro',
    isa      => Str,
);

has pin => (
    is        => 'ro',
    isa       => Bool,
    default   => 0,
);

has norecurse => (
    is        => 'ro',
    isa       => Bool,
    default   => 0,
);


has dryrun => (
    is        => 'ro',
    isa       => Bool,
    default   => 0,
);

#------------------------------------------------------------------------------

sub _build_author {
    my ($self) = @_;

    # Try looking in their .pause file
    my $pause_id = $self->pausecfg->{user};
    return uc $pause_id if $pause_id;

    # Fall back to username
    return uc $self->username;
}

#------------------------------------------------------------------------------

sub BUILD {
    my ($self, $args) = @_;

    my @missing = grep { not -e $_ } $self->archives;
    $self->error("Archive $_ does not exist") for @missing;

    my @unreadable = grep { -e $_ and not -r $_ } $self->archives;
    $self->error("Archive $_ is not readable") for @unreadable;

    throw "Some archives are missing or unreadable"
        if @missing or @unreadable;

    return $self;
}

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    my $stack = $self->repos->get_stack(name => $self->stack);

    $self->_execute($_, $stack) for $self->archives;

    return $self->result->changed;
}

#------------------------------------------------------------------------------

sub _execute {
    my ($self, $archive, $stack) = @_;

    $self->notice("Adding distribution archive $archive");

    my $dist  = $self->repos->add( archive   => $archive,
                                   author    => $self->author );

    $dist->register( stack => $stack );
    $dist->pin( stack => $stack ) if $self->pin;

    $self->pull_prerequisites( $dist, $stack ) unless $self->norecurse;

    return;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#-----------------------------------------------------------------------------
1;

__END__
