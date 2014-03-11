#!perl

use strict;
use warnings;

use Test::More;

use lib 't/lib';
use Pinto::Util qw(tempdir);
use Pinto::Tester;
use Pinto::Tester::Util qw(make_dist_archive);

#------------------------------------------------------------------------------

my $source = Pinto::Tester->new;
$source->populate('JOHN/Baz-1.2 = Baz~1.2');
$source->populate('PAUL/Nuts-2.3 = Nuts~2.3');
$source->populate('RINGO/Foo-0.6 = Foo~0.6');
$source->populate('RINGO/Loop-3.14 = Loop~3.14');
$source->populate('GEORGE/Zap-1.0 = Zap~1.0');
$source->populate('GEORGE/Noodle-1.008 = Noodle~1.008');
$source->populate('GEORGE/Rose-1.8 = Rose~1.8');

#------------------------------------------------------------------------------
{
    # Non-recursive pull
    my $local = Pinto::Tester->new( init_args => { sources => $source->stack_url } );
    my $cpanfile = $local->build_cpanfile(<<"EOCPANFILE");
requires 'Nuts', '>= 2.0, < 2.33';
EOCPANFILE

    $local->run_ok( 'Pull', { cpanfile => $cpanfile } );
    $local->registration_ok('PAUL/Nuts-2.3/Nuts~2.3');
    $local->registration_not_ok('JOHN/Baz-1.2/Baz~1.2');
}

{
    # Non-recursive pull
    my $local = Pinto::Tester->new( init_args => { sources => $source->stack_url } );
    my $cpanfile = $local->build_cpanfile(<<"EOCPANFILE");
requires 'Nuts', '< 2.00';
EOCPANFILE

    $local->run_throws_ok(
        'Pull',
        { cpanfile => $cpanfile },
        qr/Cannot find Nuts< 2.00 anywhere/,
        '... and returned expected failure message'
    );
}

{
    # Non-recursive pull
    my $local = Pinto::Tester->new( init_args => { sources => $source->stack_url } );
    my $cpanfile = $local->build_cpanfile(<<"EOCPANFILE");
requires 'Nuts', '> 2.00';
recommends 'Baz', '< 2.00';
on 'develop' => sub {
    requires 'Loop', '> 3';
    recommends 'Noodle', '> 1';
};
on 'test' => sub {
    requires 'Zap', '>= 1.0';
    recommends 'Foo', '> 0.5';
};
# conflicts not currently processed
conflicts 'Rose', '< 1.0';
EOCPANFILE

    $local->run_ok( 'Pull', { cpanfile => $cpanfile } );
    $local->registration_ok('JOHN/Baz-1.2/Baz~1.2');
    $local->registration_ok('PAUL/Nuts-2.3/Nuts~2.3');
    $local->registration_ok('RINGO/Foo-0.6/Foo~0.6');
    $local->registration_ok('RINGO/Loop-3.14/Loop~3.14');
    $local->registration_ok('GEORGE/Zap-1.0/Zap~1.0');
    $local->registration_ok('GEORGE/Noodle-1.008/Noodle~1.008');
    $local->registration_not_ok('GEORGE/Rose-1.8/Rose~1.8');
}

{
    # Bogus cpanfile
    my $local = Pinto::Tester->new( init_args => { sources => $source->stack_url } );
    my $cpanfile = $local->build_cpanfile(<<"EOCPANFILE");
# typo!
reuires 'Nuts', '> 2.00';
EOCPANFILE

    $local->run_throws_ok(
        'Pull',
        { cpanfile => $cpanfile },
        qr/Unable to load.*cpanfile/,
        'Correctly handles bogus cpanfile'
    );
}

done_testing;
