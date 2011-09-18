package Pinto::Schema::ResultSet::Distribution;

# ABSTRACT:

use strict;
use warnings;

use base qw( DBIx::Class::ResultSet );

#-------------------------------------------------------------------------------

# VERSION

#-------------------------------------------------------------------------------

sub foreigners {
    my ($self) = @_;

    my $where = { origin => {'!=' => 'LOCAL' } };
    my $attrs = { order_by => {-asc => 'path'} };

    return $self->search($where, $attrs);
}

#-------------------------------------------------------------------------------

sub locals {
    my ($self) = @_;

    my $where = { origin => 'LOCAL' };
    my $attrs = { order_by => {-asc => 'path'} };

    return $self->search($where, $attrs);
}

#-------------------------------------------------------------------------------

sub outdated {
    my ($self) = @_;

    my $where = { origin => 'LOCAL' };
    my $attrs = { order_by => {-asc => 'path'} };

    return $self->search($where, $attrs);
}

#-------------------------------------------------------------------------------

1;

__END__
