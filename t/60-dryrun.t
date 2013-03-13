#!perl

use strict;
use warnings;

use Test::More;

use Pinto::Tester;
use Pinto::Tester::Util qw(make_dist_archive);

#------------------------------------------------------------------------------

my $source = Pinto::Tester->new;
$source->populate('JOHN/Baz-1.2 = Baz~1.2 & Nuts~2.3');
$source->populate('PAUL/Nuts-2.3 = Nuts~2.3');

#------------------------------------------------------------------------------
# Do a bunch of operations with dry_run=1, and make sure repos is still empty

{
  my $local = Pinto::Tester->new(init_args => {sources => $source->stack_url});

  $local->run_ok('Pull', {dry_run => 1, targets => 'Baz~1.2'});
  $local->repository_clean_ok;

  my $archive = make_dist_archive('Qux-2.0 = Qux~2.0');

  $local->run_ok('Add', {dry_run => 1, archives => $archive});
  $local->repository_clean_ok;
}

#------------------------------------------------------------------------------

done_testing;
