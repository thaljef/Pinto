#!perl

use strict;
use warnings;

use File::Copy;
use Path::Class;
use Test::More;

use lib 't/lib';
use Pinto::Tester;
use Pinto::Tester::Util qw(make_dist_archive);

use Pinto::Util qw(sha256);

#------------------------------------------------------------------------------

my $pkg1    = 'Foo~0.01';
my $pkg2    = 'Bar~0.01';
my $dist    = 'Foo-Bar-0.01';
my $archive = make_dist_archive("$dist=$pkg1;$pkg2");

#------------------------------------------------------------------------------
# Adding a local dist...
subtest 'add local distribution' => sub {

    my $t = Pinto::Tester->new;
    $t->run_ok( 'Add', { archives => $archive } );

    $t->registration_ok("AUTHOR/$dist/$pkg1/master");
    $t->registration_ok("AUTHOR/$dist/$pkg2/master");

};

#------------------------------------------------------------------------------
# Adding a local dist using custom author identity
subtest 'add local distribution with custom author identity' => sub {

    my $t = Pinto::Tester->new;
    $t->run_ok( 'Add', { archives => $archive, author => 'ME'} );

    $t->registration_ok("ME/$dist/$pkg1/master");
    $t->registration_ok("ME/$dist/$pkg2/master");

};
#-----------------------------------------------------------------------------
# Adding to alternative stack...
subtest 'add to alternative stack' => sub {

    my $t = Pinto::Tester->new;
    $t->run_ok( 'New', { stack => 'dev' } );
    $t->run_ok( 'Add', { archives => $archive, stack => 'dev' } );

    $t->registration_ok("AUTHOR/$dist/$pkg1/dev");
    $t->registration_ok("AUTHOR/$dist/$pkg2/dev");

};

#-----------------------------------------------------------------------------
# Adding identical dist twice on same stack
subtest 'add identical distribution to same stack more than once' => sub {

    my $t = Pinto::Tester->new;
    $t->run_ok( 'Add', { archives => $archive } );
    $t->registration_ok("AUTHOR/$dist/$pkg1/master");
    $t->registration_ok("AUTHOR/$dist/$pkg2/master");

    $t->run_ok( 'Add', { archives => $archive } );
    $t->registration_ok("AUTHOR/$dist/$pkg1/master");
    $t->registration_ok("AUTHOR/$dist/$pkg2/master");

    $t->stderr_like( qr/\Q$archive\E is the same/, 'Got warning about identical dist' );

    # This time, with a pin
    $t->run_ok( 'Add', { archives => $archive, pin => 1 } );
    $t->registration_ok("AUTHOR/$dist/$pkg1/master/*");
    $t->registration_ok("AUTHOR/$dist/$pkg2/master/*");

};

#-----------------------------------------------------------------------------
# Adding identical dist twice on different stacks
subtest 'add identical distribution to different stack more than once' => sub {

    my $t = Pinto::Tester->new;
    $t->run_ok( 'Add', { archives => $archive } );
    $t->registration_ok("AUTHOR/$dist/$pkg1/master");
    $t->registration_ok("AUTHOR/$dist/$pkg2/master");

    $t->run_ok( 'New', { stack => 'dev' } );

    $t->run_ok( 'Add', { archives => $archive, stack => 'dev' } );
    $t->registration_ok("AUTHOR/$dist/$pkg1/dev");
    $t->registration_ok("AUTHOR/$dist/$pkg2/dev");

    $t->stderr_like( qr/\Q$archive\E is the same/, 'Got warning about identical dist' );

};

#-----------------------------------------------------------------------------
# Adding identical dist twice but with a pin the second time
subtest 'add identical distribution twice with pin on second try' => sub {

    my $t = Pinto::Tester->new;
    $t->run_ok( 'Add', { archives => $archive } );
    $t->registration_ok("AUTHOR/$dist/$pkg1/master");
    $t->registration_ok("AUTHOR/$dist/$pkg2/master");

    $t->run_ok( 'Add', { archives => $archive, pin => 1 } );
    $t->registration_ok("AUTHOR/$dist/$pkg1/master/*");
    $t->registration_ok("AUTHOR/$dist/$pkg2/master/*");

    $t->stderr_like( qr/\Q$archive\E is the same/, 'Got warning about identical dist' );

};

#-----------------------------------------------------------------------------
# Adding identical dists with different names
subtest 'add identical distributions with different names' => sub {

    my $archive1 = make_dist_archive("Dist-1=A~1");
    my $archive2 = file( $archive1->dir, 'MY-' . $archive1->basename );
    copy( $archive1, $archive2 ) or die "Copy failed: $!";

    is( sha256($archive1), sha256($archive2), 'Archives are identical' );
    isnt( $archive1->basename, $archive2->basename, 'Archives have different names' );

    my $t = Pinto::Tester->new;
    $t->run_ok( 'Add', { archives => $archive1 } );
    $t->run_throws_ok(
        'Add',
        { archives => $archive2 },
        qr/\Q$archive2\E is the same .* but with different name/
    );

};

#-----------------------------------------------------------------------------
# Adding multiple dists to the same path
subtest 'add multiple distributions to the same path' => sub {

    my $t = Pinto::Tester->new;

    # Two different dists with identical names...
    my $archive1 = make_dist_archive("Dist-1=A~1");
    my $archive2 = make_dist_archive("Dist-1=B~2");

    $t->run_ok( 'Add', { archives => $archive1 } );

    $t->run_throws_ok(
        'Add',
        { archives => $archive2 },
        qr/already exists/,
        'Cannot add dist to same path twice'
    );

    $t->run_throws_ok(
        'Add',
        { archives => $archive2 },
        qr/already exists/,
        'Cannot add dist to same path twice'
    );

    $t->run_throws_ok(
        'Add',
        { archives => 'bogus' },
        qr/Some archives are missing/,
        'Cannot add nonexistant archive'
    );

};

#-----------------------------------------------------------------------------
# Adding something that requires a perl (the perl prereq should be ignored)
subtest 'add something that requries a perl' => sub {

    my $t       = Pinto::Tester->new;
    my $archive = make_dist_archive("Foo-1.0 = Foo~1.0 & perl~5.10");
    $t->run_ok( 'Add', { archives => $archive } );

    $t->registration_ok("AUTHOR/Foo-1.0/Foo~1.0");

};

#-----------------------------------------------------------------------------
# Adding something that requires a core-only module (the prereq should be ignored)
subtest 'add something that requires a core-only module' => sub {

    my $t       = Pinto::Tester->new;
    my $archive = make_dist_archive("Foo-1.0 = Foo~1.0 & IPC::Open3~1.0");
    $t->run_ok( 'Add', { archives => $archive } );

    $t->registration_ok("AUTHOR/Foo-1.0/Foo~1.0");

};

#-----------------------------------------------------------------------------
subtest 'Allow dry run add on locked repo' => sub {

    my $t = Pinto::Tester->new;
    $t->run_ok( 'Lock' => {} );
    $t->stack_is_locked_ok('master');
    $t->run_ok( 'Add', { archives => $archive, dry_run => 1 } );
    $t->registration_not_ok("AUTHOR/$dist/$pkg1/master");
    $t->repository_clean_ok;

};

done_testing;
