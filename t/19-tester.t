#!perl

use Test::More;
use Pinto::Tester;

#-------------------------------------------------------------------------------

my $t = Pinto::Tester->new;

$t->populate('AUTHOR/FooAndBar-1.2=Foo-1.2,Bar-0.0');
$t->package_ok('AUTHOR/FooAndBar-1.2/Foo-1.2/default');
$t->package_ok('AUTHOR/FooAndBar-1.2/Bar-0.0/default');

#-------------------------------------------------------------------------------
done_testing;
