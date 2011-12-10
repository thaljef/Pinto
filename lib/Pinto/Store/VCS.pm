package Pinto::Store::VCS;

# ABSTRACT: Base class for VCS-backed Stores

use Moose;

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------
# ISA

extends qw( Pinto::Store );

#------------------------------------------------------------------------------
# Moose attributes

has _paths => (
    is        => 'ro',
    isa       => 'HashRef[Path::Class]',
    init_arg  => undef,
    clearer   => '_clear_paths',
    default   => sub { {} },
);

#------------------------------------------------------------------------------
# Methods

augment commit => sub {
    my ($self) = @_;

    $self->info('Committing changes to VCS');

    inner();

    $self->_clear_paths();

    return $self;
};

#------------------------------------------------------------------------------

sub mark_path_for_commit {
    my ($self, $path) = @_;

    $self->_paths->{ $path } = $path;

    return $self;
}

#------------------------------------------------------------------------------

sub paths_to_commit {
    my ($self) = @_;

    return [ sort values %{ $self->_paths() } ];
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#------------------------------------------------------------------------------
1;

__END__

