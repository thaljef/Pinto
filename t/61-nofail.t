#!perl

use strict;
use warnings;

use Test::More;

use Pinto::Tester;

#------------------------------------------------------------------------------

my $source = Pinto::Tester->new;
$source->populate('AUTHOR/DistA-1 = PkgA~1');
$source->populate('AUTHOR/DistB-1 = PkgB~1 & PkgD~1, PkgE~1'); # Depends on Pkge, but it does not exist!
$source->populate('AUTHOR/DistC-1 = PkgC~1');
$source->populate('AUTHOR/DistD-1 = PkgD~1');

#------------------------------------------------------------------------------
# An error (missing prereq in this case) should rollback all changes...

{
 
  my $local = Pinto::Tester->new(init_args => {sources => $source->stack_url});
  $local->run_throws_ok(Pull => {targets => [qw(PkgA PkgB PkgC) ]}, qr/Cannot find PkgE~1 anywhere/);

  # None of the packages should be registered because one failed...
  $local->registration_not_ok('AUTHOR/DistA-1/PkgA~1/master');
  $local->registration_not_ok('AUTHOR/DistB-1/PkgB~1/master');
  $local->registration_not_ok('AUTHOR/DistC-1/PkgC~1/master');
  $local->registration_not_ok('AUTHOR/DistD-1/PkgD~1/master');

  # The filesystem is not transactional, so the archive for A will still be there...
  $local->path_exists_ok( [qw(stacks master authors id A AU AUTHOR DistA-1.tar.gz)] );

  # And so will the archives for B and D...
  $local->path_exists_ok( [qw(stacks master authors id A AU AUTHOR DistB-1.tar.gz)] );
  $local->path_exists_ok( [qw(stacks master authors id A AU AUTHOR DistD-1.tar.gz)] );

  # But C should not be there because we never got to pull it...
  $local->path_not_exists_ok( [qw(stacks master authors id A AU AUTHOR DistC-1.tar.gz)] );

  # If we clean up those files...
  $local->pinto->repo->clean_files;

  # The the whole repo should be pure again...
  $local->repository_clean_ok;
}

#------------------------------------------------------------------------------
# If the no_fail flag is set, then only the failed ones should be rollback...

{
  my $local = Pinto::Tester->new(init_args => {sources => $source->stack_url});
  $local->run_ok(Pull => {targets => [qw(PkgA PkgB PkgC)], no_fail => 1});

  # We should see a log message saying that B failed, because E was missing...
  $local->log_like( qr/Cannot find PkgE~1 anywhere/);
  $local->log_like( qr/PkgB~0 failed...continuing/);

  # Both A and C should be registered...
  $local->registration_ok('AUTHOR/DistA-1/PkgA~1/master', 'Target before failure ok');
  $local->registration_ok('AUTHOR/DistC-1/PkgC~1/master', 'Target after failure ok');

  # But B (the middle target) should not...
  $local->registration_not_ok('AUTHOR/DistB-1/PkgB~1/master', 'But failed target should not be there');

  # Nor should any of B's prereqs...
  $local->registration_not_ok('AUTHOR/DistD-1/PkgD~1/master', 'Dependency of failed target was unregisted');

  # In fact, they shouldn't even exist in the DB...
  my $DistD = $local->pinto->repo->get_distribution(author => 'AUTHOR', archive => 'DistD-1.tar.gz');
  is $DistD, undef, 'Depedency of failed target is gone completely';

  # However, the archive for B and its prereq D will still be on the filesystem...
  my @dist_B = qw(stacks master authors id A AU AUTHOR DistB-1.tar.gz);
  my @dist_D = qw(stacks master authors id A AU AUTHOR DistD-1.tar.gz);
  $local->path_exists_ok( \@dist_B );
  $local->path_exists_ok( \@dist_D );

  # If we clean up those files...
  $local->pinto->repo->clean_files;

  # Then they should both be gone...
  $local->path_not_exists_ok( \@dist_B );
  $local->path_not_exists_ok( \@dist_D );
}

#-----------------------------------------------------------------------------

done_testing;
