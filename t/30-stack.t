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
  # Create a new stack...
  my ($stk_name, $stk_desc) = ('dev', 'the development stack');
  $t->run_ok('New', {stack => $stk_name, description => $stk_desc});
  my $stack = $t->pinto->repo->get_stack(name => $stk_name);
  is $stack->name, $stk_name, 'Got correct stack name';
  is $stack->get_property('description'), $stk_desc, 'Got correct stack description';
  my $old_mtime = $stack->head_revision->committed_on;

  sleep 2; # So the mtime changes.

  # Add to the stack...
  my $foo_and_bar_1 = make_dist_archive('FooAndBar-1 = Foo~1,Bar~1');
  $t->run_ok('Add', {author => 'ME', stack => $stk_name, archives => $foo_and_bar_1});
  $t->registration_ok( 'ME/FooAndBar-1/Foo~1/dev/-' );
  $t->registration_ok( 'ME/FooAndBar-1/Bar~1/dev/-' );

  # Should not be on the init stack...
  $t->registration_not_ok( 'ME/FooAndBar-1/Foo~1/init/-' );
  $t->registration_not_ok( 'ME/FooAndBar-1/Bar~1/init/-' );

  # Check that mtime was updated...
  $stack->refresh; # Causes it to reload from DB
  cmp_ok $stack->head_revision->committed_on, '>', $old_mtime, 'Updated stack mtime';
}

#------------------------------------------------------------------------------

{
  # Copy dev -> qa...
  my $dev_stk_name = 'dev';
  my ($qa_stk_name, $qa_stk_desc) = ('qa', 'the qa stack');
  $t->run_ok('Copy', {from_stack  => $dev_stk_name,
                      to_stack    => $qa_stk_name,});

  my $dev_stack = $t->pinto->repo->get_stack(name => $dev_stk_name);
  my $qa_stack = $t->pinto->repo->get_stack(name => $qa_stk_name);

  is $qa_stack->name, $qa_stk_name,
    'Got correct stack name';

  is $qa_stack->head_revision->compute_sha256, $dev_stack->head_revision->sha256,
    'Copied stack has same checksum';

  is $qa_stack->get_property('description'), 'copy of stack dev',
    'Copied stack has default description';
}

#------------------------------------------------------------------------------

{

  # Marking default stack...
  my $init_stack = $t->pinto->repo->get_stack;
  ok defined $init_stack, 'get_stack with no args returned a stack';
  ok $init_stack->is_default, 'init stack is the default stack';

  my $dev_stack = $t->pinto->repo->get_stack(name => 'dev');
  ok defined $dev_stack, 'got the dev stack';


  $dev_stack->mark_as_default;
  ok $dev_stack->is_default, 'dev stack is now default';

  # Force reload from DB...
  $init_stack->discard_changes;
  ok !$init_stack->is_default, 'init stack is no longer default';

  throws_ok { $init_stack->is_default(0) } qr/cannot directly set is_default/,
    'Setting is_default directly throws exception';
}

#------------------------------------------------------------------------------

{
  no warnings qw(once redefine);
  # Cause actions to fail just before they touch the file system
  local *Pinto::Action::New::edit_message = sub { die "action failed"};
  local *Pinto::Action::Copy::edit_message = sub { die "action failed"};

  # Try creating a new stack
  $t->run_throws_ok('New' => {stack => 'foobar'},
                             qr/action failed/);

  # Stack directory should not exist because commit failed
  $t->path_not_exists_ok( [ qw(foobar) ] );


  # Try copying a stack
  $t->run_throws_ok('Copy' => {from_stack => 'init',
                               to_stack   => 'foobar'},
                               qr/action failed/);

  # Stack directory should not exist becasue commit failed
  $t->path_not_exists_ok( [ qw(foobar) ] );

}

#------------------------------------------------------------------------------

{
  # Copy from a stack that doesn't exist
  $t->run_throws_ok('Copy', {from_stack => 'nowhere',
                             to_stack   => 'somewhere'},
                             qr/Stack nowhere does not exist/);


  # Copy to a stack that already exists
  $t->run_throws_ok('Copy', {from_stack => 'init',
                             to_stack   => 'dev'},
                             qr/Stack dev already exists/);


   # Copy to a stack that already exists, but with different case
  $t->run_throws_ok('Copy', {from_stack => 'init',
                             to_stack   => 'DeV'},
                             qr/Stack DeV already exists/);


  # Create stack with invalid name
  $t->run_throws_ok('New', {stack => '$bogus@'},
                            qr/must be alphanumeric/);


  # Copy to stack with invalid name
  $t->run_throws_ok('Copy', {from_stack => 'init',
                              to_stack   => '$bogus@'},
                              qr/must be alphanumeric/);

  # Copy to stack with no name
  $t->run_throws_ok('Copy', {from_stack => 'init',
                              to_stack   => ''},
                              qr/must be alphanumeric/);

  # Copy to stack with undef name
  $t->run_throws_ok('Copy', {from_stack => 'init',
                              to_stack   => undef},
                              qr/must be alphanumeric/);
}


#------------------------------------------------------------------------------

done_testing;

