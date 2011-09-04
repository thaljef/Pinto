package Pinto::Schema;

# ABSTRACT Schema for the Pinto database;

use warnings;
use strict;

use base 'DBIx::Class::Schema';

Pinto::Schema->load_namespaces();

#-----------------------------------------------------------------------------
1;

__END__
