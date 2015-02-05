#!perl

use strict;
use warnings;

use Test::More;

use lib 't/lib';
use Pinto::Tester;
use Pinto::Tester::Util qw(make_dist_archive corrupt_distribution);
use Path::Class qw(file);

#------------------------------------------------------------------------------

my $upstream = Pinto::Tester->new;

# Create a good upstream distribution
my $archive = make_dist_archive('GOOD/Foo-1.2 = Foo~1.2');
$upstream->pinto->run(
        add => { archives => $archive, author => 'GOOD', recurse => 0 },
);

# Create a bad upstream distribution
$archive = make_dist_archive('BAD/Bar-1.2 = Bar~1.2');
$upstream->pinto->run(
    add => { archives => $archive, author => 'BAD', recurse => 0 },
);
corrupt_distribution($upstream, 'BAD', 'Bar-1.2.tar.gz');

#------------------------------------------------------------------------------

subtest "Verifying upstream at level 0" => sub {
    my $local = Pinto::Tester->new( init_args => { sources => $upstream->stack_url } );

    $local->run_ok(
        'Pull',
        { targets => 'Foo~1.2', verify_upstream => 0 },
        "Good upstream distribution verifies",
    );

    $local->run_ok(
        'Pull',
        { targets => 'Bar~1.2', verify_upstream => 0 },
        "Bad upstream distribution verifies",
    );
};

subtest "Verifying upstream at level 1" => sub {
    my $local = Pinto::Tester->new( init_args => { sources => $upstream->stack_url } );

    $local->run_ok(
        'Pull',
        { targets => 'Foo~1.2', verify_upstream => 1 },
        "Good upstream distribution verifies",
    );

    $local->run_throws_ok(
        'Pull',
        { targets => 'Bar~1.2', verify_upstream => 1 },
        qr{Upstream distribution file does not verify},
        "Bad upstream distribution does not verify",
    );
};

#------------------------------------------------------------------------------

subtest "Verifying upstream at level 3" => sub {
    my $local = Pinto::Tester->new( init_args => { sources => $upstream->stack_url } );
    $local->run_throws_ok(
        'Pull',
        { targets => 'Foo~1.2', verify_upstream => 3 },
        qr{Upstream distribution file does not verify},
        "Good unsigned upstream distribution does not verify",
    );
    $local->run_throws_ok(
        'Pull',
        { targets => 'Bar~1.2', verify_upstream => 3 },
        qr{Upstream distribution file does not verify},
        "Bad unsigned upstream distribution does not verify",
    );
};

# NOTE Level test are covered better in t/02-bowels/90-verify.t.  This is
# really just a integration test to ensure the option triggers the
# verification code and the level is propagated.  The verification code (in
# Pinto::Verifier) is share by all the 4 Puller commands and the verify
# command.

#------------------------------------------------------------------------------
done_testing();
