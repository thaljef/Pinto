#!perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

use Pinto::Tester;

#------------------------------------------------------------------------------

my $t = Pinto::Tester->new;

#------------------------------------------------------------------------------

{
  # Create a stack...
  my $stack = $t->pinto->repos->create_stack(name => 'test');

  # Set a property...
  $stack->set_property(a => 1);
  is $stack->get_property('a'), 1,
    'set/get one property';

  # Set several properties...
  $stack->set_properties({b => 2, c => 3});
  is_deeply $stack->get_properties, { a => 1, b => 2, c => 3 },
    'get/set many props';

  # Copy stack...
  my $new_stack = $t->pinto->repos->copy_stack(from => $stack, to => 'qa');
  is_deeply $new_stack->get_properties, $stack->get_properties,
    'Copied stack has same properties';

  # Delete a property...
  $new_stack->delete_property('a');
  ok ! exists $new_stack->get_properties->{'a'},
    'Deleted a prop';

  # Invalid property name..
  throws_ok { $new_stack->set_property('foo#bar' => 4) }
    qr{Invalid property name};
}


#------------------------------------------------------------------------------

done_testing;

