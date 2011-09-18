package Pinto::Action::List::Foreign;

# ABSTRACT: Action that lists all the foreign packages in a repository

use Moose;

extends 'Pinto::Action::List';

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

override execute => sub {
    my ($self) = @_;

    my $rs = $self->db->foreign_packages();
    while (my $package = $rs->next() ) {
        print { $self->out() } $package->to_index_string();
    }

    return 0;
};

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#------------------------------------------------------------------------------

1;

__END__
