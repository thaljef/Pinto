#!perl

use strict;
use warnings;

use Test::More;

use lib 't/lib';
use Pinto::Tester;
use Pinto::Tester::Util qw(make_dist_archive);
use Path::Class qw(file);

#------------------------------------------------------------------------------

my $source = Pinto::Tester->new;

# Create a good upstream distribution
my $archive = make_dist_archive('GOOD/Foo-1.2 = Foo~1.2');
$source->pinto->run(
        add => { archives => $archive, author => 'GOOD', recurse => 0 },
);

# Create a bad upstream distribution
$archive = make_dist_archive('BAD/Bar-1.2 = Bar~1.2');
$source->pinto->run(
    add => { archives => $archive, author => 'BAD', recurse => 0 },
);

# Damage the BAD archive by appending junk so that the checksums are invalid
my $dist = $source->get_distribution(author => 'BAD', archive => 'Bar-1.2.tar.gz');
my $fh = $dist->native_path->opena() or die $!;
print $fh 'LUNCH'; undef  $fh;

#------------------------------------------------------------------------------

{
    my $local = Pinto::Tester->new( init_args => { sources => $source->stack_url } );

    $local->run_ok(
        'Pull',
        { targets => 'Foo~1.2', verify => 1 },
        "Good upstream distribution verifies",
    );

    $local->run_throws_ok(
        'Pull',
        { targets => 'Bar~1.2', verify => 1 },
        qr{Upstream distribution file does not verify},
        "Bad upstream distribution does not verify",
    );
}

#------------------------------------------------------------------------------

{
    my $local = Pinto::Tester->new( init_args => { sources => $source->stack_url } );
    $local->run_throws_ok(
        'Pull',
        { targets => 'Foo~1.2', verify => 1, strict => 1 },
        qr{Distribution does not have a signed checksums file},
        "Good upstream distribution does not verify strictly",
    );
    $local->run_throws_ok(
        'Pull',
        { targets => 'Bar~1.2', verify => 1, strict => 1 },
        qr{Distribution does not have a signed checksums file},
        "Bad upstream distribution does not verify strictly",
    );
}

# TODO: still have a few more permutations to explore, but they require having
# some signed distributions to test against.

done_testing();
