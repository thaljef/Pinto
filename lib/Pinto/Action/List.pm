package Pinto::Action::List;

# ABSTRACT: An action that lists the contents of a repository

use Moose;

extends 'Pinto::Action';

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    for my $package ( $self->idxmgr()->all_packages() ) {
        print $package->to_string(), "\n";
    }

    return 0;
}

#------------------------------------------------------------------------------

1;

__END__
