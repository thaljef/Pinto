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

#-----------------------------------------------------------------------------

{

  my $res = HTTP::Response->new(200);
  my $ua  = Test::LWP::UserAgent->new;
  $ua->map_response(qr{.*} => $res );

  my $action = 'Add';
  my $temp = File::Temp->new;
  my %pinto_args   = (username => 'myname');
  my %chrome_args  = (verbose => 2, no_color => 1, quiet => 0);
  my %action_args  = (archives => [$temp->filename], author => 'ME', stack => 'mystack');

  my $chrome = Pinto::Chrome::Term->new(%chrome_args);
  my $pinto = Pinto::Remote->new(root => 'myhost', ua => $ua, chrome => $chrome, %pinto_args);
  $pinto->run($action, %action_args);


  my $req = $ua->last_http_request_sent;

  is $req->method, 'POST',
      "Correct HTTP method in request for action $action";

  is $req->uri, 'http://myhost:3111/action/add',
      "Correct uri in request for action $action";

  my $req_params = parse_req_params($req);
  my $got_chrome_args = decode_json($req_params->{chrome});
  my $got_pinto_args  = decode_json($req_params->{pinto});
  my $got_action_args = decode_json($req_params->{action});

  is_deeply $got_chrome_args, \%chrome_args,
      "Correct chrome args in request for action $action";

  is_deeply $got_pinto_args, \%pinto_args,
      "Correct pinto args in request for action $action";

  is_deeply $got_action_args, \%action_args,
      "Correct action args in request for action $action";
}

#-----------------------------------------------------------------------------

sub parse_req_params {
    my ($req) = @_;
    my $type = $req->headers->header('Content-Type');
    my $length = $req->headers->header('Content-Length');
    my $hb = HTTP::Body->new($type, $length);
    $hb->add($req->content);
    return $hb->param;
}

#-----------------------------------------------------------------------------

done_testing;
