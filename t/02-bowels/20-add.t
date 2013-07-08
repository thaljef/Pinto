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

my $auth    = 'ME';
my $pkg1    = 'Foo~0.01';
my $pkg2    = 'Bar~0.01';
my $dist    = 'Foo-Bar-0.01';
my $archive = make_dist_archive("$dist=$pkg1,$pkg2");

#------------------------------------------------------------------------------
# Adding a local dist...

{

    my $t = Pinto::Tester->new;
    $t->run_ok( 'Add', { archives => $archive, author => $auth } );

    $t->registration_ok("$auth/$dist/$pkg1/master");
    $t->registration_ok("$auth/$dist/$pkg2/master");

}

#-----------------------------------------------------------------------------
# Adding to alternative stack...

{

    my $t = Pinto::Tester->new;
    $t->run_ok( 'New', { stack => 'dev' } );
    $t->run_ok( 'Add', { archives => $archive, author => $auth, stack => 'dev' } );

    $t->registration_ok("$auth/$dist/$pkg1/dev");
    $t->registration_ok("$auth/$dist/$pkg2/dev");

}

#-----------------------------------------------------------------------------
# Adding identical dist twice on same stack

{

    my $t = Pinto::Tester->new;
    $t->run_ok( 'Add', { archives => $archive, author => $auth } );
    $t->registration_ok("$auth/$dist/$pkg1/master");
    $t->registration_ok("$auth/$dist/$pkg2/master");

    $t->run_ok( 'Add', { archives => $archive, author => $auth } );
    $t->registration_ok("$auth/$dist/$pkg1/master");
    $t->registration_ok("$auth/$dist/$pkg2/master");

    $t->stderr_like( qr/\Q$archive\E is the same/, 'Got warning about identical dist' );

    # This time, with a pin
    $t->run_ok( 'Add', { archives => $archive, author => $auth, pin => 1 } );
    $t->registration_ok("$auth/$dist/$pkg1/master/*");
    $t->registration_ok("$auth/$dist/$pkg2/master/*");

}

#-----------------------------------------------------------------------------
# Adding identical dist twice on different stacks

{

    my $t = Pinto::Tester->new;
    $t->run_ok( 'Add', { archives => $archive, author => $auth } );
    $t->registration_ok("$auth/$dist/$pkg1/master");
    $t->registration_ok("$auth/$dist/$pkg2/master");

    $t->run_ok( 'New', { stack => 'dev' } );

    $t->run_ok( 'Add', { archives => $archive, author => $auth, stack => 'dev' } );
    $t->registration_ok("$auth/$dist/$pkg1/dev");
    $t->registration_ok("$auth/$dist/$pkg2/dev");

    $t->stderr_like( qr/\Q$archive\E is the same/, 'Got warning about identical dist' );

}

#-----------------------------------------------------------------------------
# Adding identical dist twice but with a pin the second time

{

    my $t = Pinto::Tester->new;
    $t->run_ok( 'Add', { archives => $archive, author => $auth } );
    $t->registration_ok("$auth/$dist/$pkg1/master");
    $t->registration_ok("$auth/$dist/$pkg2/master");

    $t->run_ok( 'Add', { archives => $archive, author => $auth, pin => 1 } );
    $t->registration_ok("$auth/$dist/$pkg1/master/*");
    $t->registration_ok("$auth/$dist/$pkg2/master/*");

    $t->stderr_like( qr/\Q$archive\E is the same/, 'Got warning about identical dist' );

}

#-----------------------------------------------------------------------------
# Adding identical dists with different names

{

    my $archive1 = make_dist_archive("Dist-1=A~1");
    my $archive2 = file( $archive1->dir, 'MY-' . $archive1->basename );
    copy( $archive1, $archive2 ) or die "Copy failed: $!";

    is( sha256($archive1), sha256($archive2), 'Archives are identical' );
    isnt( $archive1->basename, $archive2->basename, 'Archives have different names' );

    my $t = Pinto::Tester->new;
    $t->run_ok( 'Add', { archives => $archive1, author => $auth } );
    $t->run_throws_ok(
        'Add',
        { archives => $archive2, author => $auth },
        qr/\Q$archive2\E is the same .* but with different name/
    );

}

#-----------------------------------------------------------------------------
# Adding multiple dists to the same path

{

    my $t = Pinto::Tester->new;

    # Two different dists with identical names...
    my $archive1 = make_dist_archive("Dist-1=A~1");
    my $archive2 = make_dist_archive("Dist-1=B~2");

    $t->run_ok( 'Add', { archives => $archive1, author => $auth } );

    $t->run_throws_ok(
        'Add',
        { archives => $archive2, author => uc $auth },
        qr/already exists/,
        'Cannot add dist to same path twice'
    );

    $t->run_throws_ok(
        'Add',
        { archives => $archive2, author => $auth },
        qr/already exists/,
        'Cannot add dist to same path twice'
    );

    $t->run_throws_ok(
        'Add',
        { archives => 'bogus', author => $auth },
        qr/Some archives are missing/,
        'Cannot add nonexistant archive'
    );
}

#-----------------------------------------------------------------------------
# Adding something that requires a perl (the perl prereq should be ignored)

{

    my $t       = Pinto::Tester->new;
    my $archive = make_dist_archive("Foo-1.0 = Foo~1.0 & perl~5.10");
    $t->run_ok( 'Add', { archives => $archive, author => $auth } );

    $t->registration_ok("$auth/Foo-1.0/Foo~1.0");

}

#-----------------------------------------------------------------------------
# Adding something that requires a core-only module (the prereq should be ignored)

{

    my $t       = Pinto::Tester->new;
    my $archive = make_dist_archive("Foo-1.0 = Foo~1.0 & IPC::Open3~1.0");
    $t->run_ok( 'Add', { archives => $archive, author => $auth } );

    $t->registration_ok("$auth/Foo-1.0/Foo~1.0");

}

#-----------------------------------------------------------------------------

done_testing;
