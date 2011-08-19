package Pinto::Store::VCS;

# ABSTRACT: Base class for VCS-backed Stores

use Moose;
use Moose::Autobox;

extends qw(Pinto::Store);

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------
# Moose attributes

has _adds => (
    is          => 'ro',
    isa         => 'HashRef[Path::Class]',
    init_arg    => undef,
    default     => sub { {} },
);

has _deletes => (
    is          => 'ro',
    isa         => 'HashRef[Path::Class]',
    init_arg    => undef,
    default     => sub { {} },
);

has _mods => (
    is          => 'ro',
    isa         => 'HashRef[Path::Class]',
    init_arg    => undef,
    default     => sub { {} },
);

#------------------------------------------------------------------------------

# TODO: Figure out how to use a Set object and/or native trait
# delegation so that we don't have to write all these methods
# ourselves.

#------------------------------------------------------------------------------
# Methods

sub mark_path_as_added {
    my ($self, $path) = @_;

    $self->_adds->put($path->stringify(), $path);

    return $self;
}

#------------------------------------------------------------------------------

sub mark_path_as_removed {
    my ($self, $path) = @_;

    $self->_deletes->put($path->stringify(), $path);

    return $self;
}

#------------------------------------------------------------------------------

sub mark_path_as_modified {
    my ($self, $path) = @_;

    $self->_mods->put($path->stringify(), $path);

    return $self;
}

#------------------------------------------------------------------------------

sub added_paths {
    my ($self) = @_;

    return $self->_adds->values->sort->flatten();
}

#------------------------------------------------------------------------------

sub removed_paths {
    my ($self) = @_;

    return $self->_deletes->values->sort->flatten();
}

#------------------------------------------------------------------------------

sub modified_paths {
    my ($self) = @_;

    return $self->_mods->values->sort->flatten();
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#------------------------------------------------------------------------------
1;

__END__
