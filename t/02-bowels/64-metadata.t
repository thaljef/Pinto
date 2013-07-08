#!perl

use strict;
use warnings;

use Test::More;

use lib 't/lib';
use Pinto::Tester;
use Pinto::Tester::Util qw(make_dist_archive);

#------------------------------------------------------------------------------
# TODO: What we really need here are tests that verify what happens when a dist
# has broken META (or no META at all).  To do that, we need to hand-roll some
# broken distribution archives and ship them along as test data
#------------------------------------------------------------------------------

my $t = Pinto::Tester->new;
$t->populate('AUTHOR/Foo-3 = Foo-4 & Bar~1, perl~5.6.0, strict');
my $dist = $t->get_distribution( author => 'AUTHOR', archive => 'Foo-3.tar.gz' );
ok defined $dist, 'Got the distribution back';

my $meta = $dist->metadata;
isa_ok $meta, 'CPAN::Meta';
is $meta->as_struct->{version}, '3', 'META has correct dist version';
is $meta->as_struct->{provides}->{Foo}->{version}, '4', 'META has correct package version';
is $meta->as_struct->{'meta-spec'}->{version}, '2', 'META has correct meta spec version';

my $prereqs = $meta->as_struct->{prereqs};
is $prereqs->{runtime}->{requires}->{Bar},    '1',      'Requires Bar~1';
is $prereqs->{runtime}->{requires}->{perl},   'v5.6.0', 'Requires perl~5.6.0';
is $prereqs->{runtime}->{requires}->{strict}, '0',      'Requires strict~0';

#------------------------------------------------------------------------------

done_testing;
