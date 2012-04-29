#!perl

use strict;
use warnings;

use Test::More;

use Pinto::Tester;
use Pinto::Tester::Util qw(make_dist_archive);

#------------------------------------------------------------------------------

my $t = Pinto::Tester->new;

#------------------------------------------------------------------------------

{
  # Create a stack...
  my $stack = $t->pinto->repos->db->create_stack({name => 'test'});
  is_deeply $stack->get_properties, {}, 'New stack has no props';

  # Set a property
  $stack->set_property(A => 1);
  is $stack->get_property('A'), 1, 'set/get one property';

  $stack->set_properties({B => 2, C => 3});
  is_deeply $stack->get_properties, {A => 1, B => 2, C => 3}, 'set/get many props';


  # Copy the stack, and add/modify props...
  my $new_props = {A => 10, B => 20, D => 4};
  my $new_stack = $stack->copy({name => 'qa', properties => $new_props});

  is_deeply $new_stack->get_properties, {A => 10, B => 20, C => 3, D => 4},
    'Copied stack and modified its properites';

  # Delete a prop from new stack...
  $new_stack->delete_property(qw(A B));
  is_deeply $new_stack->get_properties, {C => 3, D => 4}, 'Deleted two props';

  # Delete all props from new stack...
  $new_stack->delete_properties;
  is_deeply $new_stack->get_properties, {}, 'Deleted all props';

  # Mare sure old stack is unaffected...
  is_deeply $stack->get_properties, {A => 1, B => 2, C => 3}, 'set/get many props';


}

#------------------------------------------------------------------------------

done_testing;

