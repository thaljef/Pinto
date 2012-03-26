#!perl

use strict;
use warnings;

use Test::More;

use Path::Class;

use Pinto::Tester;

#------------------------------------------------------------------------------
# Setup...

no warnings 'qw';
my @specs = qw(
    AUTHOR/Foo-Bar-1.2=Foo::Bar-1.2
    AUTHOR/FooAndBaz-2.3=Foo-2.3,Baz-2.9
);
use warnings;

my $source_repo = Pinto::Tester->new->populate( @specs );
my $source_repo_url = 'file://' . $source_repo->root();

my $test_repo = Pinto::Tester->new( creator_args => {sources => $source_repo_url} );
$test_repo->repository_empty_ok();

#------------------------------------------------------------------------------
# Mirroring a foreign repository...

$test_repo->action_ok('Mirror');
$test_repo->package_ok('AUTHOR/Foo-Bar-1.2/Foo::Bar-1.2/default');
$test_repo->package_ok('AUTHOR/FooAndBaz-2.3/Foo-2.3/default');
$test_repo->package_ok('AUTHOR/FooAndBaz-2.3/Baz-2.9/default');

done_testing();


