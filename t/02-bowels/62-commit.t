#!perl

use strict;
use warnings;

use Test::More;

use lib 't/lib';
use Pinto::Tester;

#------------------------------------------------------------------------------

use Pinto::Globals;
local $Pinto::Globals::current_username = 'ME';

#------------------------------------------------------------------------------

my $source = Pinto::Tester->new;
my $source_url = $source->stack_url;
$source->populate('AUTHOR/A-1 = PkgA~1 & PkgB');
$source->populate('AUTHOR/B-1 = PkgB~1');

#------------------------------------------------------------------------------

subtest 'No message specified' => sub {

    my $t = Pinto::Tester->new( init_args => { sources => $source_url } );

    $t->run_ok( Pull => {targets => 'PkgA'} );
    my $revision = $t->get_stack->head;

    is $revision->username, 'ME',
        'Revision was committed by ME';

    is $revision->message_title, 'Pull AUTHOR/A-1.tar.gz',
        'Message has correct title';

    is $revision->message_body,  '',
        'Message body is empty';

    is $revision->message, 'Pull AUTHOR/A-1.tar.gz',
        'Full message is title only';
};

#------------------------------------------------------------------------------

subtest 'Use default message' => sub {

    my $t = Pinto::Tester->new( init_args => { sources => $source_url } );

    $t->run_ok( Pull => {targets => 'PkgA', use_default_message => 1} );
    my $revision = $t->get_stack->head;

    is $revision->username, 'ME',
        'Revision was committed by ME';

    is $revision->message_title, 'Pull AUTHOR/A-1.tar.gz',
        'Message has correct title';

    is $revision->message_body, q{},
        'Message body is empty';

    is $revision->message, 'Pull AUTHOR/A-1.tar.gz',
        'Full message is title only';
};

#------------------------------------------------------------------------------

subtest 'Use custom message, title only' => sub {

    my $t = Pinto::Tester->new( init_args => { sources => $source_url } );

    $t->run_ok( Pull => {targets => 'PkgA', message => "TITLE\n\n"} );
    my $revision = $t->get_stack->head;

    is $revision->username, 'ME',
        'Revision was committed by ME';

    is $revision->message_title, 'TITLE',
        'Message has correct title (trailing whitespace chomped)';

    is $revision->message_body, q{},
        'Message has correct body.';

    is $revision->message, "TITLE\n\n",
        'Full message is correct (trailing whitespace intact)';
};

#------------------------------------------------------------------------------

subtest 'Use custom message, title and body' => sub {

    my $t = Pinto::Tester->new( init_args => { sources => $source_url } );

    $t->run_ok( Pull => {targets => 'PkgA', message => "TITLE\n\nBODY\n"} );
    my $revision = $t->get_stack->head;

    is $revision->username, 'ME',
        'Revision was committed by ME';

    is $revision->message_title, 'TITLE',
        'Message has correct title (trailing whitespace chomped)';

    is $revision->message_body, 'BODY',
        'Message has correct body (trailng whitespace chomped)';

    is $revision->message, "TITLE\n\nBODY\n",
        'Full message is correct (trailing whitespace intact)';
};

#------------------------------------------------------------------------------

subtest 'Custom message is just whitespace' => sub {

    my $t = Pinto::Tester->new( init_args => { sources => $source_url } );

    $t->run_ok( Pull => {targets => 'PkgA', message => " \n  \n "} );
    my $revision = $t->get_stack->head;

    is $revision->username, 'ME',
        'Revision was committed by ME';

    is $revision->message_title, 'Pull AUTHOR/A-1.tar.gz',
        'Message has correct title';

    is $revision->message_body, q{},
        'Message body is empty';

    is $revision->message, 'Pull AUTHOR/A-1.tar.gz',
        'Full message is correct';
};

#------------------------------------------------------------------------------

subtest 'Targets are sorted and de-duped' => sub {

    my $t = Pinto::Tester->new( init_args => { sources => $source_url } );

    $t->run_ok( Pull => {targets => [qw(PkgB PkgA PkgB PkgA)]} );
    my $revision = $t->get_stack->head;

    is $revision->message_title, 'Pull AUTHOR/A-1.tar.gz, AUTHOR/B-1.tar.gz',
        'Message has correct title';
};

#------------------------------------------------------------------------------

subtest 'Re-pulling target AND missing prereqs' => sub {

    my $t = Pinto::Tester->new( init_args => { sources => $source_url } );

    $t->run_ok( Pull => {targets => 'PkgA', recurse => 0} ); # Without prereqs
    $t->run_ok( Pull => {targets => [qw(PkgA PkgB)], recurse => 1} ); # With prereqs
    my $revision = $t->get_stack->head;

    is $revision->message_title, 'Pull AUTHOR/A-1.tar.gz',
        'Message has correct title';
};

#------------------------------------------------------------------------------

subtest 'Some targets fail' => sub {

    my $t = Pinto::Tester->new( init_args => { sources => $source_url } );

    $t->pinto->run( Pull => {targets => [qw(PkgA PkgC)], no_fail => 1} );
    my $revision = $t->get_stack->head;

    is $revision->message_title, 'Pull AUTHOR/A-1.tar.gz',
        'Message has correct title';
};

#------------------------------------------------------------------------------
done_testing;
