#!perl

use strict;
use warnings;

use Test::More;

use Pinto::Globals;

use lib 't/lib';
use Pinto::Tester;
use Pinto::Tester::Util qw(make_dist_archive);

#------------------------------------------------------------------------------

my $t = Pinto::Tester->new;
$Pinto::Globals::current_utc_time    = 0;    # Freeze time to begining of epoch
$Pinto::Globals::current_time_offset = 0;    # Freeze local timezone to UTC

$t->run_ok(
    Add => {
        stack    => 'master',
        archives => make_dist_archive("ME/Foo-0.01 = Foo~0.01")
    }
);

$t->run_ok(
    Copy => {
        from_stack => 'master',
        to_stack   => 'branch'
    }
);

$t->run_ok(
    Add => {
        stack    => 'branch',
        archives => make_dist_archive("ME/Bar-0.02 = Bar~0.02")
    }
);

#------------------------------------------------------------------------------

{

    my $stack = 'master';
    $t->run_ok( Log => { stack => $stack } );

    my $msgs = () = ${ $t->outstr } =~ m/revision [0-9a-f\-]{36}/g;
    is $msgs, 1, "Stack $stack has correct message count";

    $t->stdout_like( qr/Foo-0.01.tar.gz/, 'Log message has Foo archive' );

    # TODO: Consider adding hook to set username on the Tester;
    $t->stdout_like( qr/User: USERNAME/, 'Log message has correct user' );

    # This test might not be portable, based on locale settings:
    $t->stdout_like( qr/Date: Jan 1, 1970/, 'Log message has correct date' );

}

#------------------------------------------------------------------------------

{

    my $stack = 'branch';
    $t->run_ok( Log => { stack => $stack } );

    my $msgs = () = ${ $t->outstr } =~ m/revision [0-9a-f\-]{36}/g;
    is $msgs, 2, "Stack $stack has correct message count";

    $t->stdout_like( qr/Foo-0.01.tar.gz/, 'Log messages have Foo archive' );
    $t->stdout_like( qr/Bar-0.02.tar.gz/, 'Log messages have Bar archive' );

}

#-----------------------------------------------------------------------------

done_testing;
