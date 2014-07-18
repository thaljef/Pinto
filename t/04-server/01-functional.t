#!perl

use strict;
use warnings;

use Test::More;
use Plack::Test;

use JSON;
use IO::Zlib;
use Path::Class;
use HTTP::Date;
use HTTP::Request::Common;

use Pinto::Server;
use Pinto::Constants qw(:server :protocol);

use lib 't/lib';
use Pinto::Tester;
use Pinto::Tester::Util qw(make_dist_archive);

#------------------------------------------------------------------------------
# Setup...

my $t       = Pinto::Tester->new;
my %opts    = ( root => $t->pinto->root );
my $app     = Pinto::Server->new(%opts)->to_app;
my @headers = (Accept => $PINTO_PROTOCOL_ACCEPT);

#------------------------------------------------------------------------------
# Fetching an index...

test_psgi
    app    => $app,
    client => sub {
    my $cb  = shift;
    my $req = GET('modules/02packages.details.txt.gz');
    my $res = $cb->($req);

    is $res->code, 200, 'Correct status code';

    is $res->header('Content-Type'), 'application/x-gzip', 'Correct Type header';

    cmp_ok $res->header('Content-Length'), '>', 4000, 'Reasonable Length header';  # Actual length may vary
    cmp_ok $res->header('Content-Length'), '<', 7000, 'Reasonable Length header';  # Actual length may vary
    is $res->header('Content-Length'), length $res->content, 'Length header matches actual length';

    is $res->header('Cache-Control'), 'no-cache', 'Got a "Cache-Control: no-cache" header';

    isnt str2time( $res->header('Last-Modified') ), undef, 'Last-Modified header contains a proper HTTP::Date string';
    };

#------------------------------------------------------------------------------
# Test fetching legacy indexes (used by the cpan[1] client)

test_psgi
    app    => $app,
    client => sub {
    my $cb = shift;

    my @paths = qw(authors/01mailrc.txt.gz modules/03modlist.data.gz);

    for my $path (@paths) {
        for my $prefix ( 'stacks/master/', '' ) {
            my $url = $prefix . $path;
            my $req = GET($url);
            my $res = $cb->($req);
            is $res->code, 200, "Got response for $url";
            is $res->header('Cache-Control'), "no-cache", "$url got a 'Cache-Control: no-cache' header";
        }
    }
    };

#------------------------------------------------------------------------------
# Add an archive, then fetch it back.  Finally, check that all packages in the
# archive are present in the listing

{

    my $archive = make_dist_archive('TestDist-1.0=Foo~0.7; Bar~0.8')->stringify;

    test_psgi
        app    => $app,
        client => sub {
        my $cb     = shift;
        my $params = { author => 'THEBARD', recurse => 0, message => 'test', archives => [$archive] };
        my $req    = POST( 'action/add', @headers, Content => { action => encode_json($params) } );
        my $res    = $cb->($req);
        action_response_ok($res);
        };

    test_psgi
        app    => $app,
        client => sub {
        my $cb     = shift;
        my $params = { stack => 'master' };
        my $req    = POST( 'action/lock', @headers, Content => { action => encode_json($params) } );
        my $res    = $cb->($req);
        action_response_ok($res);
        };

    test_psgi
        app    => $app,
        client => sub {
        my $cb     = shift;
        my $params = { author => 'THEBARD', recurse => 0, message => 'test', archives => [$archive] };
        my $req    = POST( 'action/add', @headers, Content => { action => encode_json($params) } );
        my $res    = $cb->($req);
        action_response_not_ok( $res, qr{is locked} );
        };

    test_psgi
        app    => $app,
        client => sub {
        my $cb  = shift;
        my $url = 'stacks/master/authors/id/T/TH/THEBARD/TestDist-1.0.tar.gz';
        my $req = GET($url);
        my $res = $cb->($req);

        is $res->code, 200, "Correct status code for GET $url";

        is $res->header('Content-Type'), 'application/x-gzip', "Correct Type header for GET $url";

        is $res->header('Content-Length'), -s $archive, "Length header matches actual archive size for GET $url";

        is $res->header('Content-Length'), length $res->content,
            "Length header matches actual content length for GET $url";
        };

    my $last_modified;

    test_psgi
        app    => $app,
        client => sub {
        my $cb  = shift;
        my $url = 'stacks/master/authors/id/T/TH/THEBARD/TestDist-1.0.tar.gz';
        my $req = HEAD($url);
        my $res = $cb->($req);

        $last_modified = $res->header('Last-Modified');

        isnt str2time($last_modified), undef, "Last-Modified header contains a proper HTTP::Date string for HEAD $url";

        is $res->code, 200, "Correct status code for HEAD $url";

        is $res->header('Content-Type'), 'application/x-gzip', "Correct Type header for HEAD $url";

        is $res->header('Content-Length'), -s $archive, "Length header matches actual archive size for HEAD $url";

        is length $res->content, 0, "No content returned for HEAD $url";
        };

    test_psgi
        app    => $app,
        client => sub {
        my $cb  = shift;
        my $url = 'stacks/master/authors/id/T/TH/THEBARD/TestDist-1.0.tar.gz';
        my $req = GET( $url, 'If-Modified-Since' => $last_modified );
        my $res = $cb->($req);

        is $res->code, 304, "Correct status code for unmodified $url";

        is $res->header('Content-Type'), undef, "No Content-Type header for 304 response";

        is $res->header('Content-Length'), undef, "No Content-Length header for 304 response";

        is length $res->content, 0, "No content returned for 304 response";
        };

    test_psgi
        app    => $app,
        client => sub {
        my $cb     = shift;
        my $params = {};
        my $req    = POST( 'action/list', @headers, Content => { action_args => encode_json($params) } );
        my $res    = $cb->($req);

        is $res->code, 200, 'Correct status code';

        # Note that the lines of the listing itself should NOT contain
        # the $PINTO_PROTOCOL_DIAG_PREFIX in front of each line.

        like $res->content, qr{\s Foo \s+ 0.7 \s+ \S+ \n}mx, 'Listing contains the Foo package';

        like $res->content, qr{\s Bar \s+ 0.8 \s+ \S+ \n}mx, 'Listing contains the Bar package';
        };
}

#------------------------------------------------------------------------------
# Make two stacks, add a different version of a dist to each stack, then fetch
# the index for each stack.  The indexes should contain different dists.

for my $v ( 1, 2 ) {

    my $stack   = "stack_$v";
    my $archive = make_dist_archive("Fruit-$v=Apple~$v; Orange~$v")->stringify;

    test_psgi
        app    => $app,
        client => sub {
        my $cb     = shift;
        my $params = { stack => $stack };
        my $req    = POST( 'action/new', @headers, Content => { action => encode_json($params) } );
        my $res    = $cb->($req);

        action_response_ok($res);
        };

    test_psgi
        app    => $app,
        client => sub {
        my $cb     = shift;
        my $params = { author => 'JOHN', recurse => 0, stack => $stack, message => 'test', archives => [$archive] };
        my $req    = POST( 'action/add', @headers, Content => { action => encode_json($params) } );
        my $res    = $cb->($req);

        action_response_ok($res);
        };

    test_psgi
        app    => $app,
        client => sub {
        my $cb  = shift;
        my $req = GET("stacks/$stack/modules/02packages.details.txt.gz");
        my $res = $cb->($req);

        is $res->code, 200, 'Correct status code';

        # Write the index to a file
        my $temp = File::Temp->new;
        print {$temp} $res->content;
        close $temp;

        # Slurp index contents into memory
        my $fh = IO::Zlib->new( $temp->filename, "rb" ) or die $!;
        my $index = join '', <$fh>;
        close $fh;

        # Test index contents
        for (qw(Apple Orange)) {
            like $index, qr{^ $_ \s+ $v  \s+ J/JO/JOHN/Fruit-$v.tar.gz $}mx, "index contains package $_-$v";
        }
        };
}

#------------------------------------------------------------------------------
# GET invalid path...

test_psgi
    app    => $app,
    client => sub {
    my $cb  = shift;
    my $req = GET('bogus/path');
    my $res = $cb->($req);

    is $res->code, 404, 'Correct status code';
    is $res->header('Content-Type'),   'text/plain';
    is $res->header('Content-Length'), length $res->content;
    like $res->content, qr{not found}i, 'File not found message';
    };

#------------------------------------------------------------------------------
# POST invalid action

test_psgi
    app    => $app,
    client => sub {
    my $cb     = shift;
    my $params = {};
    my $req    = POST( 'action/bogus', @headers, Content => { action => encode_json($params) } );
    my $res    = $cb->($req);

    action_response_not_ok( $res, qr{Can't locate Pinto/Action/Bogus.pm}i );
    };

#------------------------------------------------------------------------------
# Unversioned client (no Accept header)

test_psgi
    app    => $app,
    client => sub {
    my $cb = shift;

    my $req = POST( 'action/nop', Content => { action => encode_json({}) } );
    my $res = $cb->($req);

    is $res->code, 415, 'Unsupported media type status';
    like $res->content, qr/too old/;
    like $res->content, qr/upgrade pinto/;
    };

#------------------------------------------------------------------------------
# Client version is too old (i.e. server is too new)

test_psgi
    app    => $app,
    client => sub {
    my $cb = shift;

    my @headers = (Accept => 'application/vnd.pinto.v0+text');
    my $req     = POST( 'action/nop', Content => { action => encode_json({}) } );
    my $res     = $cb->($req);

    is $res->code, 415, 'Unsupported media type status';
    like $res->content, qr/too old/;
    like $res->content, qr/upgrade pinto/;
    };

#------------------------------------------------------------------------------
# # Client version is too new (i.e. server is too old)

test_psgi
    app    => $app,
    client => sub {
    my $cb = shift;

    my @headers = (Accept => 'application/vnd.pinto.v99+text');
    my $req     = POST( 'action/nop', @headers, Content => { action => encode_json({}) } );
    my $res     = $cb->($req);

    is $res->code, 415, 'Unsupported media type status';
    like $res->content, qr/too new/;
    like $res->content, qr/upgrade pintod/;
    };

#------------------------------------------------------------------------------

sub action_response_ok {
    my ( $response, $pattern, $test_name ) = @_;

    $test_name ||= sprintf '%s %s', $response->request->method, $response->request->uri;

    # Report failues from caller's perspective
    local $Test::Builder::Level = $Test::Builder::Level + 3;

    my $type = $response->header('Content-Type');
    is $type, 'text/plain', "Content-Type response header from $test_name";

    my $status = $response->code;
    is $status, 200, "Succesful status code for $test_name";

    my $content = $response->content;

    like $content, qr{$PINTO_PROTOCOL_STATUS_OK\n$}, "Response ends with status-ok for $test_name";

    like $content, $pattern, "Response content matches for $test_name"
        if $pattern;
}

#------------------------------------------------------------------------------

sub action_response_not_ok {
    my ( $response, $pattern, $test_name ) = @_;

    $test_name ||= sprintf '%s %s', $response->request->method, $response->request->uri;

    # Report failues from caller's perspective
    local $Test::Builder::Level = $Test::Builder::Level + 3;

    my $type = $response->header('Content-Type');
    is $type, 'text/plain', "Content-Type response header from $test_name";

    my $status = $response->code;
    is $status, 200, "Succesful status code for $test_name";

    my $content = $response->content;

    unlike $content, qr{$PINTO_PROTOCOL_STATUS_OK\n$}, "Response does not end with status-ok for $test_name";

    like $content, $pattern, "Response content matches for $test_name"
        if $pattern;

}

#------------------------------------------------------------------------------

done_testing;

