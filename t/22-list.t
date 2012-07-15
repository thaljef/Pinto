#!perl

use strict;
use warnings;

use Test::More;

use Pinto::Tester;
use Pinto::Tester::Util qw(make_dist_archive);

#------------------------------------------------------------------------------


{

  my $t = Pinto::Tester->new;
  $t->run_ok( 'New' => {stack => 'dev'} );
  $t->run_ok( 'New' => {stack => 'qa'}  );

  my $archive1 = make_dist_archive("ME/Foo-0.01 = Foo~0.01");
  my $archive2 = make_dist_archive("ME/Foo-0.02 = Foo~0.02");

  $t->run_ok( 'Add' => {archives => $archive1, stack => 'dev'} );
  $t->run_ok( 'Add' => {archives => $archive2, stack => 'qa'}  );

  my $buffer = '';
  my $out = IO::String->new(\$buffer);
  $t->run_ok( 'List' => {stack => '@', out => $out} );

  like $buffer, qr/dev \s+ Foo \s+ 0.01/x, 'Listing shows Foo~0.01 in dev stack';
  like $buffer, qr/qa  \s+ Foo \s+ 0.02/x, 'Listing shows Foo~0.02 in qa stack';
}

#-----------------------------------------------------------------------------

done_testing;
