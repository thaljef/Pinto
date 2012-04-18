#!perl

use strict;
use warnings;

use Test::More;

use Path::Class;
use FindBin qw($Bin);

use Pinto::Tester;

#------------------------------------------------------------------------------

my $fakes     = dir( $Bin, qw(data fakepan repos a) );
my $auth_dir  = $fakes->subdir( qw(authors id L LO LOCAL) );
my $auth      = 'AUTHOR';

#------------------------------------------------------------------------------
# Setup...

my $t = Pinto::Tester->new();
my $pinto = $t->pinto();

#------------------------------------------------------------------------------
# Add dist and pin package Foo

my $archive = $auth_dir->file('FooOnly-0.01.tar.gz');

$pinto->new_batch();
$pinto->add_action('Stack::Create', stack => 'dev');
$pinto->add_action('Add',  stack => 'dev', author => $auth, archive => $archive);
$pinto->add_action('Pin',  stack => 'dev', package => 'Foo');

$t->result_ok( $pinto->run_actions );
$t->package_ok( "$auth/FooOnly-0.01/Foo-0.01/dev/+" );

#-----------------------------------------------------------------------------
# Now add a dist with a newer Foo, but pinned Foo should still be latest

my $newer_archive = $auth_dir->file('FooAndBar-0.02.tar.gz');

$pinto->add_action('Add', author => $auth, archive => $newer_archive, stack => 'dev');

$t->result_ok( $pinto->run_actions );
$t->package_ok( "$auth/FooOnly-0.01.tar.gz/Foo-0.01/dev" );

#-----------------------------------------------------------------------------
# Unpin Foo and add newer Foo again. The higher Foo should now be latest


$pinto->new_batch();
$pinto->add_action('Unpin', stack => 'dev', package => 'Foo');
$pinto->add_action('Remove',                author => $auth, path => 'FooAndBar-0.02.tar.gz');
$pinto->add_action('Add',   stack => 'dev', author => $auth, archive => $newer_archive);

$t->result_ok( $pinto->run_actions );
$t->package_ok( "$auth/FooAndBar-0.02.tar.gz/Foo-0.02/dev" );

#-----------------------------------------------------------------------------
# TODO: Test interraction of pinning with mirroring and importing.
# But it it should be basically the same as you see here.
#-----------------------------------------------------------------------------

done_testing();
