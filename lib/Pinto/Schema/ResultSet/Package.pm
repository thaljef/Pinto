# ABSTRACT: Common queries for Packages

use utf8;

package Pinto::Schema::ResultSet::Package;

use strict;
use warnings;

use base 'DBIx::Class::ResultSet';

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

sub with_distribution {
    my ( $self, $where ) = @_;

    return $self->search( $where || {}, { prefetch => 'distribution' } );
}

#------------------------------------------------------------------------------
1;

__END__
