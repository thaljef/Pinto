#!perl

use strict;
use warnings;

use Test::More;

use lib 't/lib';
use Pinto::Tester;
use Pinto::Tester::Util qw(make_dist_archive);

#------------------------------------------------------------------------------

my $t = Pinto::Tester->new;

#------------------------------------------------------------------------------

# Add a dist and pin it...
my $foo_and_bar = make_dist_archive('FooAndBar-1 = Foo~1; Bar~1');
$t->run_ok( 'Add', { author => 'ME', archives => $foo_and_bar } );
$t->run_ok( 'Pin', { targets => 'Foo' } );

$t->registration_ok('ME/FooAndBar-1/Foo~1/master/*');
$t->registration_ok('ME/FooAndBar-1/Bar~1/master/*');

# Now try and add a newer dist with an overlapping package...
my $bar_and_baz = make_dist_archive('BarAndBaz-2 = Bar~2; Baz~2');
$t->run_throws_ok(
    'Add',
    { author => 'ME', archives => $bar_and_baz },
    qr{Unable to register},
    'Cannot upgrade pinned package'
);

$t->stderr_like(qr{Bar is pinned});

# Now unpin the FooAndBar dist...
$t->run_ok( 'Unpin', { targets => 'Foo' } );
$t->registration_ok('ME/FooAndBar-1/Foo~1/master/-');
$t->registration_ok('ME/FooAndBar-1/Bar~1/master/-');

# Try adding the newer BarAndBaz dist again...
$t->run_ok( 'Add', { author => 'ME', archives => $bar_and_baz } );
$t->registration_ok('ME/BarAndBaz-2/Bar~2/master/-');
$t->registration_ok('ME/BarAndBaz-2/Baz~2/master/-');

# The older Foo and Bar packages should now be gone...
$t->registration_not_ok('ME/FooAndBar-1/Foo~1/master/-');
$t->registration_not_ok('ME/FooAndBar-1/Bar~1/master/-');

# Now pin Bar...
$t->run_ok( 'Pin', { targets => 'Bar' } );

# Foo-2 and Bar-2 should now be pinned...
$t->registration_ok('ME/BarAndBaz-2/Bar~2/master/*');
$t->registration_ok('ME/BarAndBaz-2/Baz~2/master/*');

#------------------------------------------------------------------------------

done_testing;

