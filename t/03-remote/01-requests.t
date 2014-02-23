#!perl

use strict;
use warnings;

use Test::More;
use Test::LWP::UserAgent;

use JSON;
use HTTP::Body;
use HTTP::Response;
use File::Temp;

use Pinto::Remote;
use Pinto::Globals;
use Pinto::Constants qw($PINTO_DEFAULT_COLORS);

use Hash::Merge;

#-----------------------------------------------------------------------------

{
    my $temp        = File::Temp->new;

    my %defaults = (
        pinto_args   => {
            username  => 'myname',
        },
        chrome_args  => {
            verbose   => 2,
            no_color  => 1,
            quiet     => 0,
            colors    => $PINTO_DEFAULT_COLORS,
        },
        expected => {
            method => 'POST',
            map { $_ => '__unchanged__' } qw(pinto_args chrome_args)
        },
    );

    my @cases = (
        {
            action => 'Add',
            root => 'myhost',
            root_uri_type => 'host only',
            action_args  => {
                archives  => [ $temp->filename ],
                author    => 'ME',
                stack     => 'mystack',
            },
            expected => {
                uri => 'http://myhost:3111/action/add',
                action_args => '__unchanged__',
            },
        },
        {
            action => 'List',
            root => 'myhost',
            root_uri_type => 'host only',
            expected => {
                uri => 'http://myhost:3111/action/list',
            },
        },
        {
            action => 'List',
            root => 'myhost/path',
            root_uri_type => 'only host and path',
            expected => { uri => 'http://myhost:3111/path/action/list' },
        },
        {
            action => 'List',
            root => 'http://myhost/path',
            root_uri_type => 'scheme and path',
            expected => { uri => 'http://myhost/path/action/list' },
        },
        {
            action => 'List',
            root => 'http://myhost:80/path',
            root_uri_type => 'scheme, port and path',
            expected => { uri => 'http://myhost:80/path/action/list' },
        },
    );

    for my $case (@cases) {
        my $args = Hash::Merge::merge($case, \%defaults);
        check_request(%$args);
    }
}

sub check_request {
    my %args = @_;
    my ($pinto_args, $chrome_args, $action_args) = @args{qw(pinto_args chrome_args action_args)};

    local $ENV{PINTO_COLORS} = undef;
    my $ua = local $Pinto::Globals::UA = Test::LWP::UserAgent->new;

    my $res = HTTP::Response->new(200);
    $ua->map_response( qr{.*} => $res );

    my $chrome = Pinto::Chrome::Term->new(%$chrome_args);
    my $pinto = Pinto::Remote->new( root => $args{root}, chrome => $chrome, %$pinto_args );
    $pinto->run( $args{action}, %$action_args );

    my $req = $ua->last_http_request_sent;

    my $expected = $args{expected};
    unless ($expected) {
        warn "No expected values for action $args{action}";
    }

    if (exists $expected->{method}) {
        is $req->method, $expected->{method}, "Correct HTTP method in request for action $args{action}";
    }

    if (exists $expected->{uri}) {
        is $req->uri, $expected->{uri}, "Correct uri in request for action $args{action}"
            . ($args{root_uri_type} ? ", root URI: $args{root_uri_type}" : '');
    }

    my $req_params = parse_req_params($req);
    my %got = (
        chrome_args => decode_json( $req_params->{chrome} ),
        pinto_args  => decode_json( $req_params->{pinto} ),
        action_args => decode_json( $req_params->{action} ),
    );

    for my $arg_name (sort keys %got) {
        if (exists $expected->{$arg_name}) {
            my $got_args = $got{$arg_name};

            my $expected_args;
            if ($expected->{$arg_name} eq '__unchanged__') {
                $expected_args = $args{$arg_name};
            } else {
                $expected_args = $expected->{$arg_name};
            }

            (my $nice_name = $arg_name) =~ s/_/ /g;

            is_deeply $got_args, $expected_args, "Correct $nice_name in request for action $args{action}";
        }
    }
}

#-----------------------------------------------------------------------------

sub parse_req_params {
    my ($req)  = @_;
    my $type   = $req->headers->header('Content-Type');
    my $length = $req->headers->header('Content-Length');
    my $hb = HTTP::Body->new( $type, $length );
    $hb->add( $req->content );
    return $hb->param;
}

#-----------------------------------------------------------------------------

done_testing;
