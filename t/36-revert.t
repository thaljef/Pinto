
#!perl

use strict;
use warnings;

use Test::More;

use Pinto::Tester;
use Pinto::Tester::Util qw(make_dist_archive);

#------------------------------------------------------------------------------
# This test follows RJBS' use case....
#------------------------------------------------------------------------------

my $cpan = Pinto::Tester->new;
$cpan->populate( 'JOHN/DistA-1 = PkgA~1 & PkgB~1',
                 'FRED/DistB-1 = PkgB~1', );

#------------------------------------------------------------------------------

my $local = Pinto::Tester->new(init_args => {sources => $cpan->stack_url});

# Suppose MyDist requires PkgA, which requires PkgB...
my $archive =  make_dist_archive('MyDist-1=MyPkg-1 & PkgA~1');
$local->run_ok(Add => {archives => $archive, author => 'ME'});

# Make a note of the commit id here, so we can revert to it later
my $good_commit_id = $local->pinto->repo->get_stack->last_commit_id;

# So we should have pulled in PkgA and PkgB...
$local->registration_ok('JOHN/DistA-1/PkgA~1');
$local->registration_ok('FRED/DistB-1/PkgB~1');

# Now, suppose that PkgA is upgraded on CPAN, and now also requires PkgC..
$cpan->populate( 'JOHN/DistA-2 = PkgA~2 & PkgB~1,PkgC-1',
                 'MARC/DistC-1 = PkgC~1', );

# So we upgrade PkgA in our local repository...
$local->clear_cache; # To get new index from CPAN
$local->run_ok(Pull => {targets => 'PkgA~2'});

# We should now have a new version PkgA, plus PkgC
$local->registration_ok('JOHN/DistA-2/PkgA~2');
$local->registration_ok('MARC/DistC-1/PkgC~1');

# Say we decide to pin PkgA now
$local->run_ok(Pin => {targets => 'PkgA'});

# PkgA should now be pinned, but not PkgB and PkgC
$local->registration_ok('JOHN/DistA-2/PkgA~2/master/*');
$local->registration_ok('FRED/DistB-1/PkgB~1/master/-');
$local->registration_ok('MARC/DistC-1/PkgC~1/master/-');

# Oops! PkgA~2 breaks our app, so revert to the last good commit...
$local->run_ok(Revert => {commit => $good_commit_id});

# PkgA should be at PkgA~1 and unpinned...
$local->registration_ok('JOHN/DistA-1/PkgA~1/master/-');

# PkgB should still be at PkgB~1...
$local->registration_ok('FRED/DistB-1/PkgB~1');

# And PkgC should be gone...
$local->registration_not_ok('MARC/DistC-1/PkgC~1');

#------------------------------------------------------------------------------

done_testing;
