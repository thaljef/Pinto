#!perl

use warnings;
use strict;

use Test::More;
use Test::Trap qw|
    trap $trap
    :flow
    :stderr(systemsafe)
    :stdout(systemsafe)
    :warn
|;

use FindBin qw( $Bin );

{
    run_cmd_and_trap( 'manual', 'init' );

    like(
        $trap->stdout, qr/creates a new repository/i,
        qq['init' manual page returned]
    );
}

# (App::Cmd::Tester doesn't capture pod2usage() pager output)
sub run_cmd_and_trap {
    my (@args) = @_;

    my $dist_base_directory = sprintf '%s/../..', $Bin;
    my $program_name = 'pinto';

    my @cmd = (
        "perl", # Running perl with perl...good times
        "-I${dist_base_directory}/lib",
        "bin/${program_name}",
    );

    my @r = trap { system ( @cmd, @args ) };

    return @r;
}

done_testing;
