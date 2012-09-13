#!perl

use strict;
use warnings;

use Test::More;

use Pinto::Tester;
use Pinto::Tester::Util qw(make_dist_archive);

#------------------------------------------------------------------------------

my $auth     = 'ME';
my $dist     = 'Foo-Bar-0.01';

my $pkg1     = 'Foo~0.01';
my $pkg2     = 'Bar~0.01';
my $archive1 = make_dist_archive("$dist=$pkg1,$pkg2");

my $pkg3     = 'Baz~0.01';
my $archive2 = make_dist_archive("$dist=$pkg1,$pkg2,$pkg3");

#-----------------------------------------------------------------------------
# Add --force ...

{
  my $t = Pinto::Tester->new;

  # other archive, same name, more pkgs

  # add pkg first time
  $t->run_ok('Add', {archives => $archive1, author => $auth});
  $t->registration_ok("$auth/$dist/$pkg1/init/-");
  $t->registration_ok("$auth/$dist/$pkg2/init/-");
  $t->registration_not_ok("$auth/$dist/$pkg3/init/-");

  # Copy to a stack that already exists
  $t->run_ok('Copy', {from_stack => 'init',
                      to_stack   => 'dev'});
  $t->registration_ok("$auth/$dist/$pkg1/dev/-");
  $t->registration_ok("$auth/$dist/$pkg2/dev/-");
  $t->registration_not_ok("$auth/$dist/$pkg3/dev/-");

  # Pin Foo-Bar in dev
  $t->run_ok('Pin', {targets => "Bar", stack => 'dev' });
  $t->registration_ok("$auth/$dist/$pkg1/dev/+");
  $t->registration_ok("$auth/$dist/$pkg2/dev/+");
  $t->registration_not_ok("$auth/$dist/$pkg3/dev/+");

  # second stack not affected from first add
  $t->registration_not_ok("$auth/$dist/$pkg1/dev/+");
  $t->registration_not_ok("$auth/$dist/$pkg2/dev/+");
  $t->registration_not_ok("$auth/$dist/$pkg3/dev/+");

  # second add with force
  $t->run_ok( 'Add', {archives => $archive2, author => $auth, force => 1},
              'Can force to add same dist twice' );

  # init stack updated to all new packages
  $t->registration_ok("$auth/$dist/$pkg1/init/-");
  $t->registration_ok("$auth/$dist/$pkg2/init/-");
  $t->registration_ok("$auth/$dist/$pkg3/init/-");

  # second stack also updated to all new packages
  $t->registration_ok("$auth/$dist/$pkg1/dev/+");
  $t->registration_ok("$auth/$dist/$pkg2/dev/+");
  $t->registration_ok("$auth/$dist/$pkg3/dev/+");
}

#-----------------------------------------------------------------------------

done_testing;
