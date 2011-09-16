package Pinto::Schema;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Schema';

__PACKAGE__->load_namespaces;


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-09-04 17:03:04
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:hiBSzrLxcuMQ+7BAWzFFSw
#-------------------------------------------------------------------------------

sub get_package {
    my ($self, $package) = @_;

    return $self->resultset('Package')->find(name => $package);
}

#-------------------------------------------------------------------------------

sub get_indexed_package {
    my ($self, $package) = @_;

   return $self->resultset('Package')->indexed->find(name => $package);
}


#-------------------------------------------------------------------------------

sub get_distribution {
    my ($self, $dist) = @_;

    return $self->resultset('Distribution')->find(location => $dist);
}


1;
