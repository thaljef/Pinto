# ABSTRACT: Attributes and methods for all Schema::Result objects

package Pinto::Role::Schema::Result;

use Moose::Role;

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

has logger  => (
   handles  => [ qw(debug info notice warning error fatal) ],
   default  => sub { $_[0]->result_source->schema->logger },
   init_arg => undef,
   lazy     => 1,
);

#------------------------------------------------------------------------------

1;

__END__
