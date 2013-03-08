#!perl

use strict;
use warnings;

use Test::More;

use Pinto::Tester;
use Pinto::Tester::Util qw(make_dist_archive);
use Pinto::PrerequisiteWalker;
use Pinto::PrerequisiteFilter::Core;

#------------------------------------------------------------------------------

# Module::Build was first introduced in perl 5.9.4 as 0.2805
# Module::Build~0.2808_01 entered perl in 5.10.0

my $t = Pinto::Tester->new;
$t->populate('AUTHOR/Foo-1 = Foo-1 & Bar~1, perl~5.6.0, strict');
$t->populate('AUTHOR/Bar-1 = Bar-1 & Module::Build~0.2808_01');

my $dist = $t->pinto->repo->get_distribution(path => 'A/AU/AUTHOR/Foo-1.tar.gz');
ok defined $dist, 'Got Foo distribution from repo';

my @total_prereqs = $dist->prerequisites;
is scalar @total_prereqs, 3, 'Dist Foo has correct number of prereqs';

#------------------------------------------------------------------------------

my %test_cases = (
	'v5.10.0' => {'Bar' => '1'                                },
	'v5.9.4'  => {'Bar' => '1', 'Module::Build' => '0.2808_01'},
	'v5.6.0'  => {'Bar' => '1', 'Module::Build' => '0.2808_01'},
);

while( my($pv, $expect) = each %test_cases) {

	my $walked_prereqs = {};

	my $cb  = sub { 
		my ($walker, $prereq) = @_;
		$walked_prereqs->{$prereq->name} = $prereq->version;
	    return $t->pinto->repo->get_distribution(spec => $prereq);
	};

	my $filter = Pinto::PrerequisiteFilter::Core->new(perl_version => $pv);
	my $walker = Pinto::PrerequisiteWalker->new(start => $dist, callback => $cb, filter => $filter);
	$walker->walk;

	# NB: 'perl' itself should never be listed as a prereq
	my $test_name = "Got expected prereqs against perl version $pv";
	is_deeply $walked_prereqs, $expect, $test_name;
}

#------------------------------------------------------------------------------

done_testing;
