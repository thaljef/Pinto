#!perl

use strict;
use warnings;

use Test::More;

use Pinto::Tester;

#------------------------------------------------------------------------------
# NOTE: 'B' is the name of a core module.  So we can't use that one
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
  # DistB-1 requires PkgC-2.  Source 1 has PkgC-1, but source 2 has PkgC-2
  my $local = Pinto::Tester->new( init_args => {sources => $sources} );
  $local->run_ok('Pull', {targets => 'PkgA~1'});
  $local->registration_ok('JOHN/DistA-1/PkgA~1');
  $local->registration_ok('JOHN/DistB-1/PkgB~1');
  $local->registration_ok('FRED/DistC-2/PkgC~2');
}

#------------------------------------------------------------------------------

{
  # DistD-1 requires PkgC-1. Source 1 has newer PkgC-1, but source 2 has newer PkgC-2
  my $local = Pinto::Tester->new( init_args => {sources => $sources} );
  $local->run_ok('Pull', {targets => 'PkgD~1'});
  $local->registration_ok('JOHN/DistD-1/PkgD~1');
  $local->registration_ok('FRED/DistC-2/PkgC~2');
}

#------------------------------------------------------------------------------

done_testing;
