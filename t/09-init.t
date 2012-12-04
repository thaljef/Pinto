#!perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

use Pinto::Tester;

#------------------------------------------------------------------------------
# Test bare repository

{
	my $t = Pinto::Tester->new;

	$t->path_exists_ok( [qw(.pinto config pinto.ini)] );
	$t->path_exists_ok( [qw(.pinto db pinto.db)] );
	$t->path_exists_ok( [qw(.pinto log)] );

	throws_ok { $t->pinto->repo->get_stack } qr/default stack has not been set/,
		'Bare repository has no stack';
}

#------------------------------------------------------------------------------
# Test repository with a default stack

{
	my $config = {stack => 'dev'};
	my $t = Pinto::Tester->new( init_args => $config );

	$t->path_exists_ok( [qw(.pinto config pinto.ini)] );
	$t->path_exists_ok( [qw(.pinto db pinto.db)] );
	$t->path_exists_ok( [qw(.pinto log)] );

	$t->path_exists_ok( [qw(dev modules 02packages.details.txt.gz)] );
	$t->path_exists_ok( [qw(dev modules 03modlist.data.gz)] );
	$t->path_exists_ok( [qw(dev authors 01mailrc.txt.gz)] );

	my $stack = $t->pinto->repo->get_stack;
	is $stack->name, 'dev',   'Initial stack has the right name';
	is $stack->is_default, 1, 'Initial stack is the default';

	is $stack->get_property('description'), 'The initial stack.',
          'Initial stack has the default description';
}

#------------------------------------------------------------------------------
# Test repository created with a stack, but not default, and custom description

{
	my $config = {stack => 'dev', nodefault => 1, description => 'my stack'};
	my $t = Pinto::Tester->new( init_args => $config );

	my $stack = $t->pinto->repo->get_stack('dev');
	is $stack->name, 'dev',   'Initial stack has the right name';
	is $stack->is_default, 0, 'Initial stack is not the default';

	is $stack->get_property('description'), 'my stack',
          'Initial stack has custom description';
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
