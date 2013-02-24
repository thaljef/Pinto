#!perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

use Pinto::Tester;

#------------------------------------------------------------------------------
# Test repository with master stack as default

{
	my $t = Pinto::Tester->new;

	$t->path_exists_ok( [qw(.pinto version)] );
	$t->path_exists_ok( [qw(.pinto config pinto.ini)] );
	$t->path_exists_ok( [qw(.pinto db pinto.db)] );
	$t->path_exists_ok( [qw(.pinto log)] );
	$t->path_exists_ok( [qw(.pinto vcs)] );

	$t->path_exists_ok( [qw(master modules 02packages.details.txt.gz)] );
	$t->path_exists_ok( [qw(master modules 03modlist.data.gz)] );
	$t->path_exists_ok( [qw(master authors 01mailrc.txt.gz)] );

	my $stack = $t->pinto->repo->get_stack('master');
	ok defined $stack, 'master stack exists';
	is $stack->name, 'master', 'master stack has correct name';
	is $stack->is_default, 1,  'master stack is the default stack';

	my $repo = $t->pinto->repo;
	is $repo->get_version, $Pinto::Repository::REPOSITORY_VERSION, 'Repo version matches';
}

#------------------------------------------------------------------------------
# Test repository created without default stack

{

	my $t = Pinto::Tester->new( init_args => {nodefault => 1} );

	my $stack = $t->pinto->repo->get_stack('master');
	ok defined $stack, 'master stack exists';
	is $stack->is_default, 0, 'master stack is not default';

	throws_ok {$t->pinto->repo->get_stack} qr/default stack has not been set/,
		'get_stack(undef) throws exception when there is no default';
}

#------------------------------------------------------------------------------
# Test custom config

{
	my $config = {sources => 'MySource', log_level => 'debug'};
	my $t = Pinto::Tester->new(init_args => $config);

	is $t->pinto->config->log_level,   'debug', 'Got custom log_level';
	is $t->pinto->config->sources,  'MySource', 'Got custom source';
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
