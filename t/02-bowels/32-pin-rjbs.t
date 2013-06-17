
#!perl

use strict;
use warnings;

use Test::More;

use lib 't/lib';
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

# PkgA requires PkgB (above). MyDist requires both PkgA and PkgB...
my $archive =  make_dist_archive('MyDist-1=MyPkg-1 & PkgA~1,PkgB~1');
$local->run_ok('Add', {archives => $archive, author => 'ME'});

# So we should have pulled in PkgA and PkgB...
$local->registration_ok('JOHN/DistA-1/PkgA~1');
$local->registration_ok('FRED/DistB-1/PkgB~1');

# Now, suppose that PkgA and PkgB both are upgraded on CPAN
$cpan->populate( 'JOHN/DistA-2 = PkgA~2 & PkgB~2',
                 'FRED/DistB-2 = PkgB~2', );

$local->clear_cache; # Make sure we get new index from CPAN

# We would like to try and upgrade to PkgA-2.  So create a new stack
$local->run_ok('Copy', {from_stack => 'master', to_stack => 'xxx'});

# Now upgrade to PkgA-2 on the xxx stack
$local->run_ok('Pull', {targets => 'PkgA~2', stack => 'xxx'});

# We should now have the new versions of both PkgA and PkgB on stack xxx
$local->registration_ok('JOHN/DistA-2/PkgA~2/xxx');
$local->registration_ok('FRED/DistB-2/PkgB~2/xxx');

# But wait!  We learn that PkgB-2 breaks our app. We want to be sure
# we don't upgrade that.  So pin it on the master (prod) stack
$local->run_ok('Pin', {targets => 'PkgB'});

# Make sure PkgB-1 is now pinned on master stack
$local->registration_ok('FRED/DistB-1/PkgB~1/master/*');

# Ooo! Super cool DistC-1 is released to CPAN
$cpan->populate('MARK/DistC-1 = PkgC~2 & PkgB~2');

$local->clear_cache; # Make sure we get new index from CPAN

# We've gotta start using DistC-1 in production!  But...
$local->run_throws_ok('Pull', {targets => 'MARK/DistC-1.tar.gz'}, qr{Unable to register});

# DistC-1 requires PkgB-2, but were are still pinned at PkgB-1...
$local->stderr_like(qr{Unable to register .* PkgB is pinned to FRED/DistB-1/PkgB~1});

# After a while, we fix our code to work with PkgB-2, so we unpin...
$local->run_ok('Unpin', {targets => 'PkgB'});

# Make sure PkgB-1 is not pinned on the master stack...
$local->registration_ok('FRED/DistB-1/PkgB~1/master/-');

#------------------------------------------------------------------------------

done_testing;
