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

#-------------------------------------------------------------------------------

subtest 'manual for valid command' => sub {
    run_cmd_and_trap( 'manual', 'init' );

    like(
        $trap->stdout, qr/creates a new repository/i,
        qq['init' manual page returned]
    );
};

#-------------------------------------------------------------------------------

subtest 'manual for invalid command' => sub {
    run_cmd_and_trap( 'manual', 'foobar' );

    like(
        $trap->stdout, qr/unrecognized command/i,
        qq['foobar' doesn't exist]
    );

    unlike(
        $trap->stdout, qr/App::Cmd::Command::commands/,
        qq[A wrong manpage is not returned]
    );

    TODO: {
        local $TODO = 'Difficult to subvert App::Cmd here';
        unlike(
            $trap->stdout, qr/Usage:/,
            qq[Usage is not attempted to be printed]
        );
    };
};

#-------------------------------------------------------------------------------
# (App::Cmd::Tester doesn't capture pod2usage() pager output)

sub run_cmd_and_trap {
    my (@args) = @_;
    my $program_name = 'pinto';

    my @cmd = ( "perl", "-Ilib", "bin/${program_name}" );

    diag("\$ $program_name @args");
    my @r = trap { system( @cmd, @args ) };

    return @r;
}

#-------------------------------------------------------------------------------
done_testing;
