#!perl

use strict;
use warnings;

use Test::More;

use Pinto::Tester;
use Pinto::Tester::Util qw(make_dist_archive);

#------------------------------------------------------------------------------

my $t = Pinto::Tester->new;

my $archive1 = make_dist_archive("ME/Foo-0.01 = Foo~0.01");
$t->run_ok( 'Add' => {archives => $archive1, stack => 'master', author => 'JOE'} );

$t->run_ok( 'Copy' => {from_stack => 'master', to_stack => 'branch'} );

my $archive2 = make_dist_archive("ME/Bar-0.02 = Bar~0.02");
$t->run_ok( 'Add' => {archives => $archive2, stack => 'branch',  author => 'JOE'} );

#------------------------------------------------------------------------------

{
  my $buffer = '';
  my $out = IO::String->new(\$buffer);
  $t->run_ok( 'Log' => {stack => 'master', out => $out} );
  warn $buffer;
}

#------------------------------------------------------------------------------

{
  my $buffer = '';
  my $out = IO::String->new(\$buffer);
  $t->run_ok( 'Log' => {stack => 'branch', out => $out} );
  warn $buffer;
}

#-----------------------------------------------------------------------------

done_testing;
