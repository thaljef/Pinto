#!perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

use lib 't/lib';
use Pinto::Tester;

#------------------------------------------------------------------------------

my $t = Pinto::Tester->new;

#------------------------------------------------------------------------------

{
  # Create a stack...
  my $stack = $t->pinto->repo->create_stack(name => 'test');

  # Set a property...
  $stack->set_property(a => 1);
  is $stack->get_property('a'), 1,
    'set/get one property';

  # Set several properties...
  $stack->set_properties({b => 2, c => 3});
  is_deeply $stack->get_properties, { a => 1, b => 2, c => 3 },
    'get/set many props at once';

  # Copy stack...
  my $new_stack = $t->pinto->repo->copy_stack(stack => $stack, name => 'qa');
  my $new_props = $new_stack->get_properties;

  # All the copied properties should be identical
  is_deeply $new_props, $stack->get_properties,
    'Copied stack has same properties';

  # Delete a property...
  $new_stack->delete_property('a');
  ok ! exists $new_stack->get_properties->{'a'},
    'Deleted a prop';

# Delete a property by setting to empty string...
  $new_stack->set_property(a => '');
  ok ! exists $new_stack->get_properties->{'a'},
    'Deleted a prop by setting to empty';

  # Invalid property name..
  throws_ok { $new_stack->set_property('foo#bar' => 4) }
    qr{Invalid property name};

  # Property names forced to lowercase...
  $new_stack->set_property(SHOUTING => 4);
  ok exists $new_stack->get_properties->{'shouting'},
    'Get/Set property irrespective of case';

  # Property names forced to lowercase...
  $new_stack->delete_property('ShOuTiNg');
  ok ! exists $new_stack->get_properties->{'shouting'},
    'Delete property irrespective of case';

}


#------------------------------------------------------------------------------

done_testing;

