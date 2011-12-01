package Pinto::Action::Rebuild;

# ABSTRACT: Rebuild the index file for the repository

use Moose;

use MooseX::Types::Moose qw(Bool);

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

extends 'Pinto::Action';

#------------------------------------------------------------------------------

has recompute => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    $self->_recompute() if $self->recompute();

    $self->add_message('Rebuilt the index');

    return 1;
}

#------------------------------------------------------------------------------

sub _recompute {
    my ($self) = @_;

    # Gotta be a better way to to do this...
    my $attrs   = {select => ['name'], distinct => 1};
    my $cursor  = $self->repos->db->select_packages(undef, $attrs)->cursor();

    while (my ($name) = $cursor->next()) {
        my $where = { name => $name };
        my $pkg = $self->repos->select_package( $where )->first();
        $self->repos->db->_mark_latest( $name );  ## no critic qw(Private)
    }

    $self->add_message('Recalculated the latest version of all packages');

    return $self;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#------------------------------------------------------------------------------

1;

__END__
