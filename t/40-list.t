#!perl

use strict;
use warnings;

use Test::More;

use Pinto::Tester;
use Pinto::Tester::Util qw(make_dist_archive);

#------------------------------------------------------------------------------

my $t = Pinto::Tester->new;
$t->run_ok( 'New' => {stack => 'dev'} );
$t->run_ok( 'New' => {stack => 'qa'}  );

my $archive1 = make_dist_archive("ME/Foo-0.01 = Foo~0.01");
my $archive2 = make_dist_archive("ME/Bar-0.02 = Bar~0.02");
my $archive3 = make_dist_archive("ME/Baz-0.03 = Baz~0.03");

$t->run_ok( 'Add' => {archives => $archive1, stack => 'dev', author => 'JOE'} );
$t->run_ok( 'Add' => {archives => $archive2, stack => 'qa',  author => 'JOE'} );
$t->run_ok( 'Add' => {archives => $archive3, stack => 'qa',  author => 'BOB'} );

#-----------------------------------------------------------------------------

{
  my $buffer = '';
  my $out = IO::String->new(\$buffer);
  $t->run_ok( 'List' => {stack => 'dev', out => $out} );
  my @lines = split /\n/, $buffer;

  is scalar @lines, 1, 'Got correct number of records in listing';
  like $lines[0], qr/Foo \s+ 0.01/x, 'Listing for dev stack';
}

#-----------------------------------------------------------------------------

{
  my $buffer = '';
  my $out = IO::String->new(\$buffer);
  $t->run_ok( 'List' => {stack => 'qa', out => $out, packages => 'Bar'} );
  my @lines = split /\n/, $buffer;

  is scalar @lines, 1, 'Got correct number of records in listing';
  like $lines[0], qr/Bar \s+ 0.02/x, 'Listing for packages matching %Bar% on qa stack';
}

#-----------------------------------------------------------------------------

{
  my $buffer = '';
  my $out = IO::String->new(\$buffer);
  $t->run_ok( 'List' => {stack => 'qa', out => $out, distributions => 'Baz'} );
  my @lines = split /\n/, $buffer;

  is scalar @lines, 1, 'Got correct number of records in listing';
  like $lines[0], qr/Baz \s+ 0.03/x, 'Listing for dists matching %Baz% on qa stack';
}

#-----------------------------------------------------------------------------

{
  my $buffer = '';
  my $out = IO::String->new(\$buffer);
  $t->run_ok( 'List' => {stack => 'qa', out => $out, author => 'BOB'} );
  my @lines = split /\n/, $buffer;

  is scalar @lines, 1, 'Got correct number of records in listing';
  like $lines[0], qr/Baz \s+ 0.03/x, 'Listing where author == BOB on qa stack';
}

#-----------------------------------------------------------------------------

done_testing;
