package Pinto::Event::List;

# ABSTRACT: An event that lists the contents of a repository

use Moose;

extends 'Pinto::Event';

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    my $idxmgr = $self->idxmgr();
    for my $package ( @{ $idxmgr->master_index()->packages() } ) {
        print $package->to_string(), "\n";
    }

    return 0;
}

#------------------------------------------------------------------------------

1;

__END__
