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
  # Create a new stack...
  my ($stk_name, $stk_desc) = ('dev', 'the development stack');
  $t->run_ok('Stack::Create', {stack => $stk_name, description => $stk_desc});
  my $stack = $t->pinto->repos->get_stack(name => $stk_name);
  is $stack->name, $stk_name, 'Got correct stack name';
  is $stack->description, $stk_desc, 'Got correct stack description';
  my $old_mtime = $stack->mtime;

  sleep 2; # So the mtime changes.

  # Add to the stack...
  my $foo_and_bar_1 = make_dist_archive('FooAndBar-1=Foo-1,Bar-1');
  $t->run_ok('Add', {author => 'ME', stack => $stk_name, archives => $foo_and_bar_1});
  $t->package_ok( 'ME/FooAndBar-1/Foo-1/dev/-' );
  $t->package_ok( 'ME/FooAndBar-1/Bar-1/dev/-' );

  # Should not be on the default stack...
  $t->package_not_ok( 'ME/FooAndBar-1/Foo-1/default/-' );
  $t->package_not_ok( 'ME/FooAndBar-1/Bar-1/default/-' );

  # Check that mtime was updated...
  $stack->discard_changes; # Causes it to reload from DB
  cmp_ok $stack->mtime, '>', $old_mtime, 'Updated stack mtime';
}

#------------------------------------------------------------------------------

{
  # Copy dev -> qa...
  my $dev_stk_name = 'dev';
  my ($qa_stk_name, $qa_stk_desc) = ('qa', 'the qa stack');
  $t->run_ok('Stack::Copy', {from_stack  => $dev_stk_name,
                             to_stack    => $qa_stk_name,
                             description => $qa_stk_desc});

  my $dev_stack = $t->pinto->repos->get_stack(name => $dev_stk_name);
  my $qa_stack = $t->pinto->repos->get_stack(name => $qa_stk_name);

  is $qa_stack->name, $qa_stk_name, 'Got correct stack name';
  is $qa_stack->description, $qa_stk_desc, 'Got correct stack description';
  is $qa_stack->mtime, $dev_stack->mtime, 'Copied stack has same mtime as origianl';
}

#------------------------------------------------------------------------------

{
  # Copy qa -> prod...
  my ($qa_stk_name, $prod_stk_name) = qw(qa prod);
  $t->run_ok('Stack::Copy', {from_stack  => $qa_stk_name,
                             to_stack    => $prod_stk_name});

  my $prod_stack = $t->pinto->repos->get_stack(name => $prod_stk_name);

  my $prod_stk_desc = "copy of stack $qa_stk_name";
  is $prod_stack->description, $prod_stk_desc, 'Got default copied stack description';
}


#------------------------------------------------------------------------------

{
  # Create a stack without description.
  my $vague_stk_name = 'vague';
  $t->run_ok('Stack::Create', {stack => $vague_stk_name});
  my $vague_stack = $t->pinto->repos->get_stack(name => $vague_stk_name);
  is $vague_stack->description, 'no description was given', 'Got default stack description';
}

#------------------------------------------------------------------------------

done_testing;

