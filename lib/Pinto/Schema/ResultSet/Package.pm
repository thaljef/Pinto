package Pinto::Schema::ResultSet::Package;

# ABSTRACT:

use strict;
use warnings;

use base qw( DBIx::Class::ResultSet );

#-------------------------------------------------------------------------------

# VERSION

#-------------------------------------------------------------------------------

sub locals {
    my ($self) = @_;

    my $where = { origin => 'LOCAL' };
    my $attrs = { prefetch => 'distribution', order_by => {-asc => 'name'} };

    return $self->search($where, $attrs);
}

#-------------------------------------------------------------------------------

sub foreigners {
    my ($self) = @_;

    my $where = { origin => {'!=' => 'LOCAL' } };
    my $attrs = { prefetch => 'distribution', order_by => {-asc => 'name'} };

    return $self->search($where, $attrs);
}

#-------------------------------------------------------------------------------

sub blocked {
    my ($self) = @_;

    my $local_pkg_names = $self->locals()->get_column('name')->as_query();
    my $where = { origin => {'!=' => 'LOCAL'}, name => {-in => $local_pkg_names} };
    my $attrs = { prefetch => 'distribution', order_by => {-asc => 'name'} };

    return $self->search($where, $attrs);
}

#-------------------------------------------------------------------------------

sub blocking {
    my ($self) = @_;

    my $foreign_pkg_names = $self->foreigners()->get_column('name')->as_query();
    my $where = { origin => 'LOCAL', name => {-in => $foreign_pkg_names} };
    my $attrs = { prefetch => 'distribution', order_by => {-asc => 'name'} };

    return $self->search($where, $attrs);
}

#-------------------------------------------------------------------------------
1;

__END__
