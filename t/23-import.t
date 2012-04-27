#!perl

use strict;
use warnings;

use Test::More;

use Pinto::Tester;
use Pinto::Tester::Util qw(make_dist_archive);

#------------------------------------------------------------------------------

my $source = Pinto::Tester->new;
$source->populate('JOHN/Baz-1.2=Baz-1.2~Nuts-2.3');
$source->populate('PAUL/Nuts-2.3=Nuts-2.3');

#------------------------------------------------------------------------------
{

  my $local = Pinto::Tester->new(creator_args => {sources => $source->root_url});
  $local->run_ok('Pull', {targets => 'Baz-1.2'});
  $local->package_ok('JOHN/Baz-1.2/Baz-1.2');
  $local->package_ok('PAUL/Nuts-2.3/Nuts-2.3');
}

#------------------------------------------------------------------------------
{

  my $local = Pinto::Tester->new(creator_args => {sources => $source->root_url});
  $local->run_throws_ok('Pull', {targets => 'Nowhere-1.2'},
                         qr/Cannot find prerequisite Nowhere-1.2/);

}

#------------------------------------------------------------------------------

done_testing;
