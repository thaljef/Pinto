#!perl

use strict;
use warnings;

use Test::More;

use Pinto::Tester;
use Pinto::Tester::Util qw(make_dist_archive);

#------------------------------------------------------------------------------

my $t = Pinto::Tester->new;

#------------------------------------------------------------------------------

# Add a dist and pin it...
my $foo_and_bar = make_dist_archive('FooAndBar-1 = Foo~1,Bar~1');
$t->run_ok('Add', {author => 'ME', archives => $foo_and_bar});
$t->run_ok('Pin', {targets => 'Foo'});

$t->registration_ok( 'ME/FooAndBar-1/Foo~1/master/*' );
$t->registration_ok( 'ME/FooAndBar-1/Bar~1/master/*' );

# Now try and add a newer dist with an overlapping package...
my $bar_and_baz = make_dist_archive('BarAndBaz-2 = Bar~2,Baz~2');
$t->run_throws_ok('Add', {author => 'ME', archives => $bar_and_baz},
                 qr{Unable to register}, 'Cannot upgrade pinned package');

$t->log_like(qr{Bar is pinned});

# Now unpin the FooAndBar dist...
$t->run_ok('Unpin',  {targets => 'Foo'});
$t->registration_ok( 'ME/FooAndBar-1/Foo~1/master/-' );
$t->registration_ok( 'ME/FooAndBar-1/Bar~1/master/-' );

# Try adding the newer BarAndBaz dist again...
$t->run_ok('Add', {author => 'ME', archives => $bar_and_baz});
$t->registration_ok( 'ME/BarAndBaz-2/Bar~2/master/-' );
$t->registration_ok( 'ME/BarAndBaz-2/Baz~2/master/-' );

# The older Bar package should now be gone...
$t->registration_not_ok( 'ME/FooAndBar-1/Bar~1/master/-' );

# But Foo should still be there...
$t->registration_ok( 'ME/FooAndBar-1/Foo~1/master/-' );

# Now try to pin Foo again...
$t->run_ok('Pin', {targets => 'Foo'});

# The old Foo-1 should now be pinned...
$t->registration_ok( 'ME/FooAndBar-1/Foo~1/master/*' );

# And the old Bar-1 should still be gone...
$t->registration_not_ok( 'ME/FooAndBar-1/Bar~1/master' );

# So if I pull all of FooAndBar back onto the stack...
$t->run_ok('Pull', {targets => 'ME/FooAndBar-1.tar.gz'});
$t->log_like(qr{Downgrading package ME/BarAndBaz-2/Bar~2 to ME/FooAndBar-1/Bar~1});

# The old Foo-1 should still be pinned...
$t->registration_ok( 'ME/FooAndBar-1/Foo~1/master/*' );

# But now Bar-1 is also there, but not pinned...
$t->registration_ok( 'ME/FooAndBar-1/Bar~1/master/-' );

# And Baz-1 should still be there from before...
$t->registration_ok( 'ME/BarAndBaz-2/Baz~2/master/-' );

# But Bar-2 should now be gone...
$t->registration_not_ok( 'ME/BarAndBaz-2/Bar~2/master' );

# Whew!

#------------------------------------------------------------------------------

done_testing;

