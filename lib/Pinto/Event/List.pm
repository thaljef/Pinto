package Pinto::Event::List;

# ABSTRACT: An event that list the contents of a repository

use Moose;

use Carp;
use Path::Class;

use Pinto::IndexManager;

extends 'Pinto::Event';

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    my $idx_mgr = Pinto::IndexManager->instance();
    for my $package ( @{ $idx_mgr->master_index()->packages() } ) {
        print $package->to_string(), "\n";
    }

    return 0;
}

#------------------------------------------------------------------------------

1;

__END__
