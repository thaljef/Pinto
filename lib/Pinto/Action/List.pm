package Pinto::Action::List;

# ABSTRACT: An action that lists the contents of a repository

use Moose;

extends 'Pinto::Action';

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    # TODO: accept an alternative filehandle for output.
    # TODO: force log_level to quiet when running this action.

    for my $package ( $self->idxmgr()->all_packages() ) {
        print $package->to_string(), "\n";
    }

    return 0;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#------------------------------------------------------------------------------

1;

__END__
