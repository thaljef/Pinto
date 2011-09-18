package Pinto::Schema::ResultSet::Package;

# ABSTRACT:

use strict;
use warnings;

use base qw( DBIx::Class::ResultSet );

#-------------------------------------------------------------------------------

# VERSION

#-------------------------------------------------------------------------------

sub every {
    my ($self) = @_;

    my $attrs = { order_by => { -asc => 'name' } };

    return $self->search(undef, $attrs);
}

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

sub latest {
    my ($self) = @_;

    my $locals_rs      = $self->locals();
    my $subquery_where = { name  => { '=' => \'me.name'  } };
    my $subquery_attrs = { alias => 'me2' };

    my $subquery = $locals_rs->search($subquery_where, $subquery_attrs)
        ->get_column('version_numeric')->max_rs->as_query();

    return  $locals_rs->search( { version_numeric => { '=' => $subquery } } );

}

#-------------------------------------------------------------------------------

sub indexed {
    my ($self) = @_;

    my $local_pkg_names = $self->locals()->get_column('name')->as_query();
    my $where = { -or => [ -and => [ origin => {'!=' => 'LOCAL'}, name => {-not_in => $local_pkg_names} ], origin => 'LOCAL' ] };
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
