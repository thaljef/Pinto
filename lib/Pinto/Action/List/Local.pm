package Pinto::Action::List::Local;

# ABSTRACT: Action that lists only the local packages in a repository

use Moose;

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------
# ISA

extends 'Pinto::Action::List';

#------------------------------------------------------------------------------

override packages => sub {
    my ($self) = @_;

    my $where = { is_local => 1, should_index => $self->indexed() };

    return $self->db->get_all_packages($where);
};

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#------------------------------------------------------------------------------

1;

__END__
