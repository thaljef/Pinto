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

  # Set a property...
  $stack->set_property(A => 1);
  is $stack->get_property('A'), 1,
    'set/get one property';

  # Set several properties...
  $stack->set_properties({B => 2, C => 3});
  is_deeply $stack->get_properties, { A => 1, B => 2, C => 3 },
    'get/set many props';

  # Copy stack...
  my $new_stack = $stack->copy_deeply({name => 'qa'});
  is_deeply $new_stack->get_properties, $stack->get_properties,
    'Copied stack has same properties';

  # Delete a property...
  $new_stack->delete_property('A');
  ok ! exists $new_stack->get_properties->{'A'},
    'Deleted a prop';

  # Prop changes update mtime and muser....
  my $mtime = $new_stack->last_modified_on;

  {
    local $ENV{USER} = 'NOBODY';
    sleep 2; # ensure time change
    $new_stack->set_property('D' => 4);
  }

  cmp_ok $new_stack->last_modified_on, '>', $mtime,
    'mtime has increased';

  is $new_stack->last_modified_by, 'NOBODY',
    'muser has changed';
}

#------------------------------------------------------------------------------

done_testing;

