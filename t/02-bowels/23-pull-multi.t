#!perl

use strict;
use warnings;

use Test::More;

use lib 'tlib';
use Pinto::Tester;

#------------------------------------------------------------------------------

my $source_1 = Pinto::Tester->new;
$source_1->populate( 'JOHN/DistA-1 = PkgA~1 & PkgB~1',
                     'JOHN/DistB-1 = PkgB~1 & PkgC~2',
                     'JOHN/DistC-1 = PkgC~1',
                     'JOHN/DistD-1 = PkgD~1 & PkgC~1' );

my $source_2 = Pinto::Tester->new;
$source_2->populate( 'FRED/DistB-1 = PkgB~1',
                     'FRED/DistC-2 = PkgC~2' );

my $sources  = sprintf '%s %s', $source_1->stack_url, $source_2->stack_url;

#------------------------------------------------------------------------------

{
  # DistB-1 requires PkgC-2.  Source 1 only has PkgC-1, but source 2 has PkgC-2
  my $local = Pinto::Tester->new( init_args => {sources => $sources} );
  $local->run_ok('Pull', {targets => 'PkgA~1'});
  $local->registration_ok('JOHN/DistA-1/PkgA~1');
  $local->registration_ok('JOHN/DistB-1/PkgB~1');
  $local->registration_ok('FRED/DistC-2/PkgC~2');
}

#------------------------------------------------------------------------------

{
  # DistD-1 requires PkgC-1. Source 1 has PkgC-1, but source 2 has even 
  # newer PkgC-2.  Since Source 1 is the first source, we should only get PkgC~1.

  my $local = Pinto::Tester->new( init_args => {sources => $sources} );
  $local->run_ok('Pull', {targets => 'PkgD~1'});
  $local->registration_ok('JOHN/DistD-1/PkgD~1');
  $local->registration_ok('JOHN/DistC-1/PkgC~1');
}

#------------------------------------------------------------------------------

{
  # Same as last test but with cascade => 1, we should get newer PkgC~2
  # from Source 2, because it is the latest amongst all upstream repos.

  my $local = Pinto::Tester->new( init_args => {sources => $sources} );
  $local->run_ok('Pull', {targets => 'PkgD~1', cascade => 1});
  $local->registration_ok('JOHN/DistD-1/PkgD~1');
  $local->registration_ok('FRED/DistC-2/PkgC~2');
}

#------------------------------------------------------------------------------

done_testing;
