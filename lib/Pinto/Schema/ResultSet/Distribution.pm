package Pinto::Schema::ResultSet::Distribution;

# ABSTRACT:

use strict;
use warnings;

use List::MoreUtils qw(none);

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

    my $attrs = { prefetch => 'packages', order_by => {-asc => 'path'} };
    my $rs = $self->search(undef, $attrs);

    my @outdated;
    while ( my $dist = $rs->next() ) {
        push @outdated, $dist if none { $_->should_index() } $dist->packages();
    }

    my $new_rs = $self->result_source->resultset();
    $new_rs->set_cache(\@outdated);

    return $new_rs;
}

#-------------------------------------------------------------------------------

1;

__END__
