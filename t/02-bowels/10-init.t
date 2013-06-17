#!perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

use lib 't/lib';
use Pinto::Tester;

#------------------------------------------------------------------------------
# Test repository with master stack as default

{
	my $t = Pinto::Tester->new;

	$t->path_exists_ok( [qw(.pinto version)] );
	$t->path_exists_ok( [qw(.pinto cache)]   );
	$t->path_exists_ok( [qw(.pinto log)]   );
	$t->path_exists_ok( [qw(.pinto config pinto.ini)] );
	$t->path_exists_ok( [qw(.pinto db pinto.db)] );

	$t->path_exists_ok( [qw(modules 02packages.details.txt.gz)] );
	$t->path_exists_ok( [qw(modules 03modlist.data.gz)] );
	$t->path_exists_ok( [qw(authors 01mailrc.txt.gz)] );

	$t->path_exists_ok( [qw(stacks master modules 02packages.details.txt.gz)] );
	$t->path_exists_ok( [qw(stacks master modules 03modlist.data.gz)] );
	$t->path_exists_ok( [qw(stacks master authors 01mailrc.txt.gz)] );

	my $stack = $t->pinto->repo->get_stack('master');
	ok defined $stack, 'master stack exists';
	is $stack->name,         'master', 'stack has correct name';
	is $stack->is_default,          1, 'stack is the default stack';
	is $stack->head->is_root,       1, 'stack is at root revision';
	is $stack->head->is_committed,  1, 'root revision is committed';

	my $repo = $t->pinto->repo;
	is $repo->get_version, $Pinto::Repository::REPOSITORY_VERSION, 'Repo version matches';
}

#------------------------------------------------------------------------------
# Test repository created without default stack

{
	my $t = Pinto::Tester->new( init_args => {no_default => 1} );
	$t->no_default_stack_ok;
}

#------------------------------------------------------------------------------
# Test repository created with custom stack name

{
	my $t = Pinto::Tester->new( init_args => {stack => 'custom'} );
	$t->stack_is_default_ok('custom');
}

#------------------------------------------------------------------------------
# Test custom config

{
	my $config = {sources => 'MySource'};
	my $t = Pinto::Tester->new(init_args => $config);
	is $t->pinto->repo->config->sources,  'MySource', 'Got custom source';
}

#------------------------------------------------------------------------------
# Test schema version

{
	my $t = Pinto::Tester->new;
	my $schema_version = $t->pinto->repo->db->schema->schema_version;
	is $schema_version, $Pinto::Schema::SCHEMA_VERSION, 'Schema version matches';
}

#------------------------------------------------------------------------------

done_testing;
