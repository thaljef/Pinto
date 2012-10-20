#!perl

use strict;
use warnings;

use Test::More;

use Pinto::Tester;
use Pinto::Tester::Util qw(make_dist_archive);

#------------------------------------------------------------------------------

my $auth    = 'Me';
my $pkg1    = 'Foo~0.01';
my $pkg2    = 'Bar~0.01';
my $dist    = 'Foo-Bar-0.01';
my $archive = make_dist_archive("$dist=$pkg1,$pkg2");

#------------------------------------------------------------------------------
# Adding a local dist...

{
  my $t = Pinto::Tester->new;
  $t->run_ok('Add', {archives => $archive, author => $auth});

  $t->registration_ok("$auth/$dist/$pkg1/init");
  $t->registration_ok("$auth/$dist/$pkg2/init");
}

#-----------------------------------------------------------------------------
# Adding to alternative stack...

{
  my $t = Pinto::Tester->new;
  $t->run_ok('New', {stack => 'dev'});
  $t->run_ok('Add', {archives => $archive, author => $auth, stack => 'dev'});

  $t->registration_ok( "$auth/$dist/$pkg1/dev" );
  $t->registration_ok( "$auth/$dist/$pkg2/dev" );
}

#-----------------------------------------------------------------------------
# Exceptions...

{
  my $t = Pinto::Tester->new;

  $t->run_ok('Add', {archives => $archive, author => $auth});

  $t->run_throws_ok( 'Add', {archives => $archive, author => uc $auth},
                     qr/already exists/, 'Cannot add dist to same path twice' );

  $t->run_throws_ok( 'Add', {archives => $archive, author => $auth},
                     qr/already exists/, 'Cannot add dist to same path twice' );

  $t->run_throws_ok( 'Add', {archives => $archive, author => 'JOE'},
                     qr/is identical/, 'Cannot add identical dists to different paths' );

  $t->run_throws_ok( 'Add', {archives => 'bogus', author => $auth},
                     qr/Some archives are missing/, 'Cannot add nonexistant archive' );
}

#-----------------------------------------------------------------------------
# Adding something that requires a perl (the perl prereq should be ignored)

{
  my $t = Pinto::Tester->new;
  my $archive = make_dist_archive("Foo-1.0 = Foo~1.0 & perl~5.10");
  $t->run_ok('Add', {archives => $archive, author => $auth});

  $t->registration_ok( "$auth/Foo-1.0/Foo~1.0" );
}

#-----------------------------------------------------------------------------
# Adding something that requires a core-only module (the prereq should be ignored)

{
  my $t = Pinto::Tester->new;
  my $archive = make_dist_archive("Foo-1.0 = Foo~1.0 & IPC::Open3~1.0");
  $t->run_ok('Add', {archives => $archive, author => $auth});

  $t->registration_ok( "$auth/Foo-1.0/Foo~1.0" );
}

#-----------------------------------------------------------------------------

done_testing;
