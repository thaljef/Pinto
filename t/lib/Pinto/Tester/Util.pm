package Pinto::Tester::Util;

# ABSTRACT: Static helper functions for testing

use strict;
use warnings;

use Pinto::Schema;

use base 'Exporter';

#-------------------------------------------------------------------------------

# VERSION

#-------------------------------------------------------------------------------

our @EXPORT_OK = qw( make_dist make_pkg );

#-------------------------------------------------------------------------------

sub make_pkg {
    my %attrs = @_;
    return Pinto::Schema->resultset('Package')->new_result( \%attrs );
}

#------------------------------------------------------------------------------

sub make_dist {
    my %attrs = @_;
    return Pinto::Schema->resultset('Distribution')->new_result( \%attrs );
}

#------------------------------------------------------------------------------
1;

__END__
