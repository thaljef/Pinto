# ABSTRACT: Common queries for Registrations

use utf8;

package Pinto::Schema::ResultSet::Registration;

use strict;
use warnings;

use base 'DBIx::Class::ResultSet';

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

sub with_package {
    my ( $self, $where ) = @_;

    return $self->search( $where || {}, { prefetch => 'package' } );
}

#------------------------------------------------------------------------------

sub with_distribution {
    my ( $self, $where ) = @_;

    return $self->search( $where || {}, { prefetch => 'distribution' } );
}

#------------------------------------------------------------------------------

sub with_revision {
    my ( $self, $where ) = @_;

    return $self->search( $where || {}, { revision => 'distribution' } );
}

#------------------------------------------------------------------------------

sub as_hash {
    my ( $self, $cb ) = @_;

    $cb ||= sub { return ( $_[0]->id => $_[0] ) };
    my %hash = map { $cb->($_) } $self->all;

    return wantarray ? %hash : \%hash;
}

#------------------------------------------------------------------------------
1;

__END__
