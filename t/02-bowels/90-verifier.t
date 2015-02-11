#!perl

use strict;
use warnings;

use Test::More;
use Test::File;

use lib 't/lib';
use Pinto::Tester;
use Pinto::Tester::Util qw( make_dist_archive corrupt_distribution );

use Pinto::Verifier;
use Pinto::ArchiveUnpacker;
use File::Which;
use Path::Class qw(file dir);
use FindBin;
use CPAN::Checksums;
use Module::Signature;
use Cwd::Guard qw(cwd_guard);
use Capture::Tiny qw(capture_stderr);

#------------------------------------------------------------------------------

sub corrupt_checksums {
    my ($repo, $author, $archive) = @_;

    # Append junk to the end of the corresponding CHECKSUMS, so that it is
    # still valid, but signature tests will fail

    my $dist = $repo->get_distribution(author => $author, archive => $archive);
    my $checksums = file($dist->native_path->parent, 'CHECKSUMS');
    my $fh = $dist->native_path->opena() or die $!;
    print $fh '# GaRbAgE'; undef  $fh;

    return;
}

#------------------------------------------------------------------------------

sub sign_checksums {
    my ($repo, $author, $archive, $trusted) = @_;

    my $dist = $repo->get_distribution(author => $author, archive => $archive);

    my $dir = $dist->native_path->parent;

    # these are the keys used by our testing keyring
    my $key = $trusted ? 'C5713B29' : '90D594AF';

    local $CPAN::Checksums::SIGNING_KEY     = $key;
    local $CPAN::Checksums::SIGNING_PROGRAM = "gpg --clearsign --default-key ";
    CPAN::Checksums::updatedir($dir);

    return;
}

#------------------------------------------------------------------------------

sub sign_dist_archive {
    my ( $archive, $trusted, $damage ) = @_;

    # XXX this is a collection of ugly hacks!

    my $unpacker = Pinto::ArchiveUnpacker->new( archive => $archive );
    my $dir = $unpacker->unpack();

    my $cwd_guard = cwd_guard($dir)
      or die "failed chdir to $dir: $Cwd::Guard::Error";

    # Add the soon to be created SIGNATURE file to the MANIFEST
    my $fh = $dir->file('MANIFEST')->opena
      or die "Could not open MANIFEST for append";
    print $fh "\nSIGNATURE";
    undef $fh;

    my $conf_file = file($ENV{GNUPGHOME},'gpg.conf');
    $conf_file->remove if $trusted; # left over from prior failed run?

    if (!$trusted) {
        # Module::Signature is going to sign using your default key and there is no
        # mechanism to override that, so temporarily make a GPG configuration
        # change

        my $fh = $conf_file->opena or die "Could not open gpg.conf for write";
        print $fh "default-key 90D594AF\n";
        undef $fh;
    }

    capture_stderr {
        Module::Signature::sign();
    };

    $conf_file->remove; # lets be clean

    if ($damage) {
        # Invalidate the signature by adding an extra file
        $dir->file('FOO')->touch();
        my $fh = $dir->file('MANIFEST')->opena
          or die "Could not open MANIFEST for append";
        print $fh "\nFOO";
        undef $fh;
    }

    # Rebuild the archive
    # TODO there has got to be a more portable way to do this
    # Maybe Archive::Any::Create, but thats a lot of work

    chdir $dir->parent;
    if ( $archive =~ /\.zip$/ ) {
        system( 'zip', '-r', $archive, $dir->basename ) == 0
          or die "Failed to create new zip archive: $!";
    }
    else {
        system( 'tar', '-czf', $archive, $dir->basename ) == 0
          or die "Failed to create new tar archive: $!";
    }

    return;
}

#-----------------------------------------------------------------------------

sub test_verify {

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

        capture_stderr {
            ok($verifier->verify_upstream(), "Upstream verifies")
        } or warn $verifier->failure, "\n";

        capture_stderr {
            ok($verifier->verify_local(),    "Local verifies")
        } or warn $verifier->failure, "\n";
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

        capture_stderr {
            ok(!$verifier->verify_upstream(), "Upstream does not verify");
            ok(!$verifier->verify_local(),    "Local does not verify");
        }
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

    test_verify(1, $local);
};

#-----------------------------------------------------------------------------

SKIP: {

    skip "Requires GnuPG", 2 unless which('gpg');

    my $homedir = dir( $FindBin::Bin, '..', 'gnupg' )->resolve();
    local $ENV{GNUPGHOME} = $homedir;
    local $ENV{PINTO_GNUPGHOME} = $homedir;
    # if we dont do this we get flooded with warnings
    chmod 0700, $homedir;  # TODO more portable way of doing this

    #-----------------------------------------------------------------------------

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

        test_verify(2, $local);
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

        test_verify(3, $local);
    };

    #-----------------------------------------------------------------------------

    subtest "Verification level 4" => sub {

        # At level 4, we also verify the unpacked distribution using the
        # embedded SIGNATURE file if it exists.  Warnings about unknown or
        # untrusted PGP keys relating to that file are printed.

        my $upstream = Pinto::Tester->new();

        # Create a valid signed upstream distribution with a valid
        # embeded signature
        my $archive = make_dist_archive('GOOD/Foo-1.2 = Foo~1.2');
        sign_dist_archive( $archive, 0, 0 );
        $upstream->pinto->run(
            'add' => { archives => $archive, author => 'GOOD', recurse => 0 }
        );

        # sign the CHECKSUMS with a trusted signature
        sign_checksums($upstream, 'GOOD', 'Foo-1.2.tar.gz', 1);

        # Create a valid signed upstream distribution with an invalid
        # embeded signature
        $archive = make_dist_archive('BAD/Bar-1.2 = Bar~1.2');
        sign_dist_archive( $archive, 0, 1 );
        $upstream->pinto->run(
            add => { archives => $archive, author => 'BAD', recurse => 0 },
        );

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

        test_verify(4, $local);
    };

    #-----------------------------------------------------------------------------

    subtest "Verification level 5" => sub {

        # At level 5, warnings about unknown or untrusted PGP keys relating to
        # embedded SIGNATURE files are now considered fatal.

        my $upstream = Pinto::Tester->new();

        # Create a valid signed upstream distribution with a valid
        # embeded signature
        my $archive = make_dist_archive('GOOD/Foo-1.2 = Foo~1.2');
        sign_dist_archive( $archive, 1, 0 );
        $upstream->pinto->run(
            'add' => { archives => $archive, author => 'GOOD', recurse => 0 }
        );

        # sign the CHECKSUMS with a trusted signature
        sign_checksums($upstream, 'GOOD', 'Foo-1.2.tar.gz', 1);

        # Create a valid signed upstream distribution with an valid
        # but untrusted embeded signature
        $archive = make_dist_archive('BAD/Bar-1.2 = Bar~1.2');
        sign_dist_archive( $archive, 0, 0 );
        $upstream->pinto->run(
            add => { archives => $archive, author => 'BAD', recurse => 0 },
        );

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

        test_verify(5, $local);
    };
}

done_testing();
