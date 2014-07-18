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

subtest 'Excluding with exact match' => sub {

    my $t       = Pinto::Tester->new;
    my $archive = make_dist_archive('Foo-Bar-0.01 = Foo~0.01; Bar~0.01');
    $t->run_ok( Add => { archives => $archive, no_index => ['Foo'] } );

    $t->registration_not_ok("AUTHOR/Foo-Bar-0.01/Foo~0.01/master");
    $t->registration_ok("AUTHOR/Foo-Bar-0.01/Bar~0.01/master");

    my $dist = $t->get_distribution( path => 'A/AU/AUTHOR/Foo-Bar-0.01.tar.gz' );
    my @pkgs = $dist->packages;

    is( scalar @pkgs,   1,     "Dist $dist has only one package" );
    is( $pkgs[0]->name, 'Bar', "Remaining package is Bar" );

};

#-----------------------------------------------------------------------------

subtest 'Excluding with regexes' => sub {

    my $t       = Pinto::Tester->new;
    my $archive = make_dist_archive('Foo-Bar-0.01 = Foo~0.01; Bar~0.01; Baz~0.01');
    $t->run_ok( Add => { archives => $archive, no_index => [ '/F', '/r' ] } );

    $t->registration_not_ok("AUTHOR/Foo-Bar-0.01/Foo~0.01/master");
    $t->registration_not_ok("AUTHOR/Foo-Bar-0.01/Bar~0.01/master");
    $t->registration_ok("AUTHOR/Foo-Bar-0.01/Baz~0.01/master");

    my $dist = $t->get_distribution( path => 'A/AU/AUTHOR/Foo-Bar-0.01.tar.gz' );
    my @pkgs = $dist->packages;

    is( scalar @pkgs,   1,     "Dist $dist has only one package" );
    is( $pkgs[0]->name, 'Baz', "Remaining package is Baz" );
};

#-----------------------------------------------------------------------------

subtest 'Excluding all packages in the dist' => sub {

    my $t       = Pinto::Tester->new;
    my $archive = make_dist_archive('Foo-0.01 = Foo~0.01');
    $t->run_throws_ok(
        Add => { archives => $archive, no_index => ['/o'] },
        qr/has no packages left/, 'Cannot exclude all packages'
    );
};

#-----------------------------------------------------------------------------

done_testing;
