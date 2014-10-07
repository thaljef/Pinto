#!perl

use strict;
use warnings;

use Test::More;
use DateTime;

use Pinto::Remote;

use lib 't/lib';
use Pinto::Server::Tester;
use Pinto::Tester::Util qw(make_dist_archive);

#------------------------------------------------------------------------------

my $t = Pinto::Server::Tester->new->start_server;
plan skip_all => "Can't open connection to $t" unless $t->can_connect;

#------------------------------------------------------------------------------

subtest 'User vs Local vs UTC time' => sub {


    my $remote = Pinto::Remote->new( root => $t->server_url );
    my $archive = make_dist_archive('AUTHOR/DistA-1 = PkgA~1');

    my $offset = 10;

    {
        local $Pinto::Globals::current_time_offset = $offset;
        my $result = $remote->run( Add => ( archives => [$archive->stringify] ) );
        ok $result->was_successful, 'Add action was successful';
    }

    my $rev = $t->get_stack->head;
    my $utc_time = $rev->utc_time;

    is $rev->time_offset, $offset, 'Time offset';

    is $rev->datetime->epoch,       $utc_time,  'UTC datetime';
    is $rev->datetime_user->epoch,  $utc_time,  'User datetime utc';
    is $rev->datetime_local->epoch, $utc_time,  'Local datetime utc';

    my $local_offset = DateTime->now( time_zone => 'local' )->offset;

    is $rev->datetime->offset,       0,              'UTC datetime offset';
    is $rev->datetime_user->offset,  $offset,        'User datetime offset';
    is $rev->datetime_local->offset, $local_offset,  'Local datetime offset';

    is $rev->to_string('%u'), $rev->datetime_local->strftime('%c'),
        'Stringify to local time';
};
#------------------------------------------------------------------------------
done_testing;

