#!perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

use Pinto::Tester;
use Pinto::Tester::Util qw(make_dist_archive);

#------------------------------------------------------------------------------

my $t = Pinto::Tester->new;

#------------------------------------------------------------------------------

{
  # Create a stack...
  my $stack = $t->pinto->repos->db->create_stack({name => 'test'});

  # Set a property...
  $stack->set_property(a => 1);
  is $stack->get_property('a'), 1,
    'set/get one property';

  # Set several properties...
  $stack->set_properties({b => 2, c => 3});
  is_deeply $stack->get_properties, { a => 1, b => 2, c => 3 },
    'get/set many props';

  # Copy stack...
  my $new_stack = $stack->copy_deeply({name => 'qa'});
  is_deeply $new_stack->get_properties, $stack->get_properties,
    'Copied stack has same properties';

  # Delete a property...
  $new_stack->delete_property('a');
  ok ! exists $new_stack->get_properties->{'a'},
    'Deleted a prop';

  # Prop changes update mtime and muser....
  my $mtime = $new_stack->last_modified_on;

  {
    local $ENV{USER} = 'NOBODY';
    sleep 2; # ensure time change
    $new_stack->set_property('d' => 4);
  }

  cmp_ok $new_stack->last_modified_on, '>', $mtime,
    'mtime has increased';

  is $new_stack->last_modified_by, 'NOBODY',
    'muser has changed';

  # Invalid property name
  throws_ok { $new_stack->set_property('foo#bar' => 4) }
    qr{Invalid property name};
}


#------------------------------------------------------------------------------

done_testing;

