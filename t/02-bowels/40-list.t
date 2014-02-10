#!perl

use strict;
use warnings;

use Test::More;

use lib 't/lib';
use Pinto::Tester;
use Pinto::Tester::Util qw(make_dist_archive);

#------------------------------------------------------------------------------

my $t = Pinto::Tester->new;
$t->run_ok( 'New' => { stack => 'dev' } );
$t->run_ok( 'New' => { stack => 'qa' } );

my $archive1 = make_dist_archive("ME/Foo-0.01 = Foo~0.01");
my $archive2 = make_dist_archive("ME/Bar-0.02 = Bar~0.02");
my $archive3 = make_dist_archive("ME/Baz-0.03 = Baz~0.03");

$t->run_ok( 'Add' => { archives => $archive1, stack => 'dev', author => 'JOE' } );
$t->run_ok( 'Add' => { archives => $archive2, stack => 'qa',  author => 'JOE' } );
$t->run_ok( 'Add' => { archives => $archive3, stack => 'qa',  author => 'BOB' } );

#-----------------------------------------------------------------------------

{
    $t->run_ok( 'List' => { stack => 'dev' } );
    my @lines = split /\n/, ${ $t->outstr };

    is scalar @lines, 1, 'Got correct number of records in listing';
    like $lines[0], qr/Foo \s+ 0.01/x, 'Listing for dev stack';
}

#-----------------------------------------------------------------------------

{
    $t->run_ok( 'List' => { stack => 'qa', packages => 'B' } );
    my @lines = split /\n/, ${ $t->outstr };

    is scalar @lines, 2, 'Got correct number of records in listing';
    like $lines[0], qr/Bar \s+ 0.02/x, 'Listing for packages matching /B/ on qa stack';
    like $lines[1], qr/Baz \s+ 0.03/x, 'Listing for packages matching /B/ on qa stack';
}

#-----------------------------------------------------------------------------

{
    $t->run_ok( 'List' => { stack => 'qa', authors => '^B.B' } );
    my @lines = split /\n/, ${ $t->outstr };

    is scalar @lines, 1, 'Got correct number of records in listing';
    like $lines[0], qr/Baz \s+ 0.03/x, 'Listing for author matching /^B.B/ on qa stack';
}

#-----------------------------------------------------------------------------

{
    $t->run_ok( 'List' => { stack => 'dev', distributions => 'oo-' } );
    my @lines = split /\n/, ${ $t->outstr };

    is scalar @lines, 1, 'Got correct number of records in listing';
    like $lines[0], qr/Foo \s+ 0.01/x, 'Listing for distribution matching /oo/ on qa stack';
}

#-----------------------------------------------------------------------------

{
    # Testing result status...

    my $result;
    $t->run_ok( New => {stack => 'foo'});

    $result = $t->pinto->run( List => { stack => 'foo' });
    is $result->was_successful, 0, 'Listing an empty stack is successfull';

    $result = $t->pinto->run( List => { stack => 'foo', authors => 'nomatch' });
    is $result->was_successful, 0, 'No matches means unsuccessful';
}

# TODO: Add tests for --all option

#-----------------------------------------------------------------------------

done_testing;
