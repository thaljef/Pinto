#!perl

use strict;
use warnings;

use Test::More;
use Plack::Test;

use HTTP::Request::Common;

use Pinto::Server;

use lib 't/lib';
use Pinto::Tester;

#------------------------------------------------------------------------------
# Setup...

my $t    = Pinto::Tester->new;
my %opts = ( root => $t->pinto->root );
my $app  = Pinto::Server->new(%opts)->to_app;

#------------------------------------------------------------------------------
# GET a path outside the repository

test_psgi
    app    => $app,
    client => sub {
        my $cb  = shift;

        my $base = 'foobar.txt';
        my $file = $t->pinto->root->parent->file("$base");

        unless ($file->open('w')) {
            pass && diag 'Cannot create test file, skipping test';
            return;
        }

        my $req = GET("../$base");
        is $cb->($req)->code, 404, 'Status of files outside repo';
        $file->remove if -e $file;
    };

#------------------------------------------------------------------------------

done_testing;

