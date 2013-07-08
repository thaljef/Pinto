#!perl

use strict;
use warnings;

use Test::More;

use Pinto::PrerequisiteWalker;

use lib 't/lib';
use Pinto::Tester;

#------------------------------------------------------------------------------

# Module::Build was first introduced in perl 5.9.4 as 0.2805
# Module::Build~0.2808_01 entered perl in 5.10.0

my $t = Pinto::Tester->new;
$t->populate('AUTHOR/Foo-1 = Foo-1 & Bar~1, perl~5.6.0, strict');
$t->populate('AUTHOR/Bar-1 = Bar-1 & Module::Build~0.2808_01');

my $dist = $t->pinto->repo->get_distribution( path => 'A/AU/AUTHOR/Foo-1.tar.gz' );
ok defined $dist, 'Got Foo distribution from repo';

my @total_prereqs = $dist->prerequisites;
is scalar @total_prereqs, 3, 'Dist Foo has correct number of prereqs';

#------------------------------------------------------------------------------

my %bar  = ( 'Bar'           => '1' );
my %mb   = ( 'Module::Build' => '0.2808_01' );
my %core = ( 'perl'          => 'v5.6.0', 'strict' => '0' );

my %test_cases = (
    'v5.10.0' => {%bar},
    'v5.9.4'  => { %bar, %mb },
    'v5.6.0'  => { %bar, %mb },
    '0'       => { %bar, %mb, %core },
);

while ( my ( $pv, $expect ) = each %test_cases ) {

    my $walked_prereqs = {};

    my $cb = sub {
        my ($prereq) = @_;
        $walked_prereqs->{ $prereq->package_name } = $prereq->package_version;
        return $t->pinto->repo->get_distribution( spec => $prereq->as_spec );
    };

    # If $pv is not a true value, then do not make a filter
    my %filter = $pv ? ( filter => sub { $_[0]->is_perl || $_[0]->is_core( in => $pv ) } ) : ();

    my $walker = Pinto::PrerequisiteWalker->new( start => $dist, callback => $cb, %filter );
    while ( $walker->next ) { }

    my $test_name = "Got expected prereqs against perl version $pv";
    is_deeply $walked_prereqs, $expect, $test_name;
}

#------------------------------------------------------------------------------

done_testing;
