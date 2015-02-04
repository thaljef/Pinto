#!perl

use strict;
use warnings;

use Test::More;
use Test::File;

use lib 't/lib';
use Pinto::Tester;
use Pinto::Tester::Util qw(make_dist_archive corrupt_distribution);

use Pinto::Verifier;

#-----------------------------------------------------------------------------

my $upstream = Pinto::Tester->new();

# Create a valid upstream distribution
my $archive = make_dist_archive('GOOD/Foo-1.2 = Foo~1.2');
$upstream->pinto->run(
    'add' => { archives => $archive, author => 'GOOD', recurse => 0 }
);

# Create a bad upstream distribution
$archive = make_dist_archive('BAD/Bar-1.2 = Bar~1.2');
$upstream->pinto->run(
    add => { archives => $archive, author => 'BAD', recurse => 0 },
);
corrupt_distribution($upstream, 'BAD', 'Bar-1.2.tar.gz');

# Pull both distributions to a local repo
my $local
  = Pinto::Tester->new( init_args => { sources => $upstream->stack_url } );
$local->pinto->run( pull => { targets => 'Foo~1.2', recurse => 0 } );
$local->pinto->run( pull => { targets => 'Bar~1.2', recurse => 0, no_fail => 1 } );


#-----------------------------------------------------------------------------

subtest "Verifying good upstream distribtion" => sub {
    my $dist
      = $local->get_distribution( author => 'GOOD', archive => 'Foo-1.2.tar.gz' );

    my $verifier = Pinto::Verifier->new(
        local    => $dist->native_path,
        upstream => $dist->source,
        level    => 1,
    );

    my $checksums = $verifier->upstream_checksums;
    file_exists_ok( $checksums => "Upstream checksums exist" );
    ok( $verifier->verify_checksum($checksums) => 'Upstream checksum verifies' );

    $checksums = $verifier->local_checksums;
    file_exists_ok( $checksums => "Local checksums exist" );
    ok( $verifier->verify_checksum($checksums) => 'Local checksum verifies' );

};

#-----------------------------------------------------------------------------

subtest "Verifying an bad upstream distribution" => sub {

    my $dist
      = $local->get_distribution( author => 'BAD', archive => 'Bar-1.2.tar.gz' );

    my $verifier = Pinto::Verifier->new(
        local    => $dist->native_path,
        upstream => $dist->source,
        level    => 1,
    );

    my $checksums = $verifier->upstream_checksums;
    file_exists_ok( $checksums => "Upstream checksums exist" );
    ok(! $verifier->verify_checksum($checksums) => 'Upstream checksum does not verify' );

    $checksums = $verifier->local_checksums;
    file_exists_ok( $checksums => "Local checksums exist" );
    ok( $verifier->verify_checksum($checksums) => 'Local checksum verifies' );

};

TODO: {
    local $TODO = 'Once we add some signed distribution files';

    ok(0 => 'Embedded good signature verifies');
    ok(0 => 'Attached good signature verifies');

    ok(0 => 'Embedded bad signature does not verify');
    ok(0 => 'Attached bad signature does not verify');
}

done_testing();
