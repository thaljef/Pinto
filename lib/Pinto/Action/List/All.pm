package Pinto::Action::List::All;

# ABSTRACT: Action that lists all the packages in a repository

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

    my $where = { should_index => $self->indexed() };

    return $self->db->get_all_packages($where);
};


#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#------------------------------------------------------------------------------

1;

__END__
