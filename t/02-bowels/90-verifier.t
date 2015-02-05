#!perl

use strict;
use warnings;

use Test::More;
use Test::File;

use lib 't/lib';
use Pinto::Tester;
use Pinto::Tester::Util qw(
    make_dist_archive
    corrupt_distribution
    corrupt_checksums
    sign_checksums
    sign_dist_archive
);

use Pinto::Verifier;
use File::Which;
use FindBin;
use Path::Class q(dir);

#-----------------------------------------------------------------------------

sub test_checksums {

    my ($level, $local ) = @_;

    #-----------------------------------------------------------------------------

    subtest "Distribution is good" => sub {

        my $dist = $local->get_distribution(
            author => 'GOOD',
            archive => 'Foo-1.2.tar.gz',
        );

        my $verifier = Pinto::Verifier->new(
            local    => $dist->native_path,
            upstream => $dist->source,
            level    => $level,
        );

        ok($verifier->verify_upstream(), "Upstream verifies")
            or warn $verifier->failure, "\n";
        ok($verifier->verify_local(),    "Local verifies")
            or warn $verifier->failure, "\n";
    };

    #-----------------------------------------------------------------------------

    subtest "Distribution is bad" => sub {

        my $dist = $local->get_distribution(
            author  => 'BAD',
            archive => 'Bar-1.2.tar.gz',
        );

        my $verifier = Pinto::Verifier->new(
            local    => $dist->native_path,
            upstream => $dist->source,
            level    => $level,
        );

        ok(!$verifier->verify_upstream(), "Upstream does not verify");
        ok(!$verifier->verify_local(),    "Local does not verify");
    };
}

#-----------------------------------------------------------------------------

subtest "Verification level 1" => sub {

    # At level 1, we verify the distributions checksum using the upstream
    # CHECKSUMS file.

    my $upstream = Pinto::Tester->new();

    # Create a valid unsigned upstream distribution
    my $archive = make_dist_archive('GOOD/Foo-1.2 = Foo~1.2');
    $upstream->pinto->run(
        'add' => { archives => $archive, author => 'GOOD', recurse => 0 }
    );

    # Create a upstream distribution with a corrupted archive
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

    # corrupt our local version of the bad archive too
    corrupt_distribution($local, 'BAD', 'Bar-1.2.tar.gz');

    test_checksums(1, $local);
};

SKIP: {

    skip "Requires GnuPG", 2 unless which('gpg');

    local $ENV{GNUPGHOME} = dir( $FindBin::Bin, '..', 'gnupg' )->resolve();
    local $ENV{PINTO_GNUPGHOME} = $ENV{GNUPGHOME};

    #-----------------------------------------------------------------------------

=comment

    subtest "Verification level 2" => sub {

        # At level 2, we also verify the signature on the upstream CHECKSUMS
        # file if it has one.  Warnings about unknown or untrusted PGP keys
        # relating to that file are printed.

        my $upstream = Pinto::Tester->new();

        # Create a valid signed upstream distribution
        my $archive = make_dist_archive('GOOD/Foo-1.2 = Foo~1.2');
        $upstream->pinto->run(
            'add' => { archives => $archive, author => 'GOOD', recurse => 0 }
        );
        sign_checksums($upstream, 'GOOD', 'Foo-1.2.tar.gz');

        # Create a upstream distribution with a corrupted CHECKSUMS file
        # signature
        $archive = make_dist_archive('BAD/Bar-1.2 = Bar~1.2');
        $upstream->pinto->run(
            add => { archives => $archive, author => 'BAD', recurse => 0 },
        );
        sign_checksums( $upstream, 'BAD', 'Bar-1.2.tar.gz' );
        corrupt_checksums( $upstream, 'BAD', 'Bar-1.2.tar.gz' );

        # Pull both distributions to a local repo
        my $local
        = Pinto::Tester->new( init_args => { sources => $upstream->stack_url } );
        $local->pinto->run( pull => { targets => 'Foo~1.2', recurse => 0 } );
        $local->pinto->run( pull => { targets => 'Bar~1.2', recurse => 0, no_fail => 1 } );

        sign_checksums( $local, 'GOOD', 'Foo-1.2.tar.gz' );
        sign_checksums( $local, 'BAD',  'Bar-1.2.tar.gz' );
        corrupt_checksums( $local, 'BAD', 'Bar-1.2.tar.gz' );

        test_checksums(2, $local);
    };

    #-----------------------------------------------------------------------------

    subtest "Verification level 3" => sub {

        # At level 3, we also require upstream CHECKSUMS files to be signed.
        # Warnings about unknown or untrusted PGP keys relating to that file
        # are now considered fatal.

        my $upstream = Pinto::Tester->new();

        # Create a valid signed upstream distribution using a trusted
        # signature
        my $archive = make_dist_archive('GOOD/Foo-1.2 = Foo~1.2');
        $upstream->pinto->run(
            'add' => { archives => $archive, author => 'GOOD', recurse => 0 }
        );
        sign_checksums($upstream, 'GOOD', 'Foo-1.2.tar.gz', 1);

        # Create a upstream distribution with an untrusted signature on the
        # CHECKSUMS file
        $archive = make_dist_archive('BAD/Bar-1.2 = Bar~1.2');
        $upstream->pinto->run(
            add => { archives => $archive, author => 'BAD', recurse => 0 },
        );
        sign_checksums( $upstream, 'BAD', 'Bar-1.2.tar.gz', 0);

        # Pull both distributions to a local repo
        my $local
          = Pinto::Tester->new( init_args => { sources => $upstream->stack_url } );

        $local->pinto->run( pull => { targets => 'Foo~1.2', recurse => 0 } );
        $local->pinto->run( pull => { targets => 'Bar~1.2', recurse => 0, no_fail => 1 } );

        sign_checksums( $local, 'GOOD', 'Foo-1.2.tar.gz', 1 );
        sign_checksums( $local, 'BAD',  'Bar-1.2.tar.gz', 0 );

        test_checksums(3, $local);
    };

=cut

    subtest "Verification level 4" => sub {

        # At level 4, we also verify the unpacked distribution using the
        # embedded SIGNATURE file if it exists.  Warnings about unknown or
        # untrusted PGP keys relating to that file are printed.

        my $upstream = Pinto::Tester->new();

        # Create a valid signed upstream distribution with a valid
        # embeded signature
        my $archive = make_dist_archive('GOOD/Foo-1.2 = Foo~1.2');
        sign_dist_archive($archive);
        $upstream->pinto->run(
            'add' => { archives => $archive, author => 'GOOD', recurse => 0 }
        );

        # sign the CHECKSUMS with a trusted signature
        sign_checksums($upstream, 'GOOD', 'Foo-1.2.tar.gz', 1);

        # Create a valid signed upstream distribution with an invalid
        # embeded signature
        $archive = make_dist_archive('BAD/Bar-1.2 = Bar~1.2');
        sign_dist_archive($archive);
        $upstream->pinto->run(
            add => { archives => $archive, author => 'BAD', recurse => 0 },
        );
        corrupt_distribution($upstream, 'BAD', 'Bar-1.2.tar.gz');

        # sign the CHECKSUMS with a trusted signature
        sign_checksums( $upstream, 'BAD', 'Bar-1.2.tar.gz', 1);

        # Pull both distributions to a local repo
        my $local
          = Pinto::Tester->new( init_args => { sources => $upstream->stack_url } );

        $local->pinto->run( pull => { targets => 'Foo~1.2', recurse => 0 } );
        $local->pinto->run( pull => { targets => 'Bar~1.2', recurse => 0, no_fail => 1 } );

        # sign the local CHECKSUMS with a trusted signature
        sign_checksums( $local, 'GOOD', 'Foo-1.2.tar.gz', 1 );
        sign_checksums( $local, 'BAD',  'Bar-1.2.tar.gz', 1 );

        test_checksums(4, $local);
    };

    # subtest "Verification level 5" => sub {

         # At level 5, warnings about unknown or untrusted PGP keys relating to
         # embedded SIGNATURE files are now considered fatal.

    # };
}

done_testing();
