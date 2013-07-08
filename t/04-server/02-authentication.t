#!perl

use strict;
use warnings;

use Test::More;
use Plack::Test;

use JSON;
use HTTP::Request;

use Pinto::Server;
use Pinto::Constants qw(:server);

use lib 't/lib';
use Pinto::Tester;
use Pinto::Tester::Util qw(make_htpasswd_file);

#------------------------------------------------------------------------------
# Create a repository and configure server

my $t             = Pinto::Tester->new;
my @credentials   = qw(my_login my_password);
my $htpasswd_file = make_htpasswd_file(@credentials);
my $auth          = { backend => 'Passwd', path => $htpasswd_file->stringify };
my %opts          = ( root => $t->pinto->root, auth => $auth );
my $app           = Pinto::Server->new(%opts)->to_app;

my $auth_required_rx = qr/authorization required/i;

#------------------------------------------------------------------------------

test_psgi
    app    => $app,
    client => sub {
    my $cb = shift;

    my $post_req = HTTP::Request->new( POST => "/action/list" );
    my $post_res = $cb->($post_req);

    ok !$post_res->is_success, 'POST request without authentication failed';
    like $post_res->content, $auth_required_rx, 'Expected content';

    my $get_req = HTTP::Request->new( GET => "/init/modules/02packages.details.txt.gz" );
    my $get_res = $cb->($get_req);

    ok !$get_res->is_success, 'GET request without authentication failed';
    like $get_res->content, $auth_required_rx, 'Expected content';

    };

#------------------------------------------------------------------------------

test_psgi
    app    => $app,
    client => sub {
    my $cb = shift;

    my $post_req = HTTP::Request->new( POST => "/action/list" );
    $post_req->authorization_basic(@credentials);
    my $post_res = $cb->($post_req);

    ok $post_res->is_success, 'POST request with correct password succeeded';
    like $post_res->content, qr{$PINTO_SERVER_STATUS_OK\n$}, 'Got status-ok';

    my $get_req = HTTP::Request->new( GET => "modules/02packages.details.txt.gz" );
    $get_req->authorization_basic(@credentials);
    my $get_res = $cb->($get_req);

    ok $get_res->is_success, 'POST request with correct password succeeded';

    # TODO: maybe test headers, body.
    };

#------------------------------------------------------------------------------

test_psgi
    app    => $app,
    client => sub {
    my $cb = shift;

    my @bad_credentials = qw(my_login my_bogus_password);

    my $post_req = HTTP::Request->new( POST => "/action/list" );
    $post_req->authorization_basic(@bad_credentials);
    my $post_res = $cb->($post_req);

    ok !$post_res->is_success, 'POST request with invalid password failed';
    like $post_res->content, $auth_required_rx, 'Expected content';

    my $get_req = HTTP::Request->new( GET => "/init/modules/02packages.details.txt.gz" );
    $get_req->authorization_basic(@bad_credentials);
    my $get_res = $cb->($get_req);

    ok !$get_res->is_success, 'GET request without authentication failed';
    like $get_res->content, $auth_required_rx, 'Expected content';
    };

#------------------------------------------------------------------------------

done_testing;
