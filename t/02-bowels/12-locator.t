#!perl

use strict;
use warnings;

use Test::More;
use Test::LWP::UserAgent;

use JSON;
use HTTP::Response;

use lib 't/lib';
use Pinto::Tester;
use Pinto::Target;
use Pinto::Constants qw(:stratopan);

#-----------------------------------------------------------------------------
# We are going to make 2 upstream repositories.  The first will pretend to be 
# cpan.stratopan.com.  We will also intercept requests to the stratopan locator
# service and give responses that point to our fake cpan.stratopan.com The 
# second upstream will pretend to be a CPAN mirror.  If the locator service
# fails or cannot give a response, we should fall back to the mirror.
#-----------------------------------------------------------------------------

my $stratopan = Pinto::Tester->new;
my $stratopan_rx = qr{^$stratopan};
$stratopan->populate('AUTHOR/Dist-1 = PkgA~1');
note "Stratopan source is $stratopan";

my $mirror = Pinto::Tester->new;
my $mirror_rx = qr{^$mirror};
$mirror->populate('AUTHOR/Dist-2 = PkgA~2');
note "Mirror source is $mirror";

my $sources = "http://cpan.stratopan.com $mirror";

#-----------------------------------------------------------------------------

subtest 'Stratopan has package' => sub {
    
    my $location = {
        package => 'PkgA', 
        version => '1', 
        uri     => "$stratopan/authors/id/A/AU/AUTHOR/Dist-1.tar.gz",
    };

    my $target = Pinto::Target->new('PkgA');
    set_up_test_ua($target, 200, [$location] );
    
    my $t = Pinto::Tester->new(init_args => {sources => $sources});
    $t->run_ok(Pull => {targets => $target});
    $t->registration_ok('AUTHOR/Dist-1/PkgA~1');

    my $dist = $t->get_distribution(target => $target);
    like $dist->source, $stratopan_rx, 'Target was pulled from stratopan';
};

#-----------------------------------------------------------------------------

subtest 'Mirror has package' => sub {
    
    my $target = Pinto::Target->new('PkgA');

    set_up_test_ua($target, 200, []);
    
    my $t = Pinto::Tester->new(init_args => {sources => $sources});
    $t->run_ok(Pull => {targets => $target});
    $t->registration_ok('AUTHOR/Dist-2/PkgA~2');

    my $dist = $t->get_distribution(target => $target);
    like $dist->source, $mirror_rx, 'Target was pulled from mirror';
};

#-----------------------------------------------------------------------------

subtest 'Nobody has package' => sub {
    
    my $target = Pinto::Target->new('PkgA==3');
    set_up_test_ua($target, 200, []);
    
    my $t = Pinto::Tester->new(init_args => {sources => $sources});
    $t->run_throws_ok(Pull => {targets => $target}, qr/Cannot find PkgA==3 anywhere/);
};

#-----------------------------------------------------------------------------

subtest 'Want latest package (cascade)' => sub {

    my $location = {
        package => 'PkgA', 
        version => '1', 
        uri     => "$stratopan/authors/id/A/AU/AUTHOR/Dist-1.tar.gz",
    };
    
    my $target = Pinto::Target->new('PkgA');
    set_up_test_ua($target, 200, [$location]);

    my $t = Pinto::Tester->new(init_args => {sources => $sources});
    $t->run_ok(Pull => {targets => $target, cascade => 1});
    $t->registration_ok('AUTHOR/Dist-2/PkgA~2');

    my $dist = $t->get_distribution(target => $target);
    like $dist->source, $mirror_rx, 'Target was pulled from mirror';
};

#-----------------------------------------------------------------------------

subtest 'Stratopan not responding' => sub {
    
    my $target = Pinto::Target->new('PkgA~2');
    set_up_test_ua($target, 500);

    my $t = Pinto::Tester->new(init_args => {sources => $sources});
    $t->run_ok(Pull => {targets => $target});
    $t->stderr_like(qr/Stratopan is not responding/);
    $t->registration_ok('AUTHOR/Dist-2/PkgA~2');

    my $dist = $t->get_distribution(target => $target);
    like $dist->source, $mirror_rx, 'Target was pulled from mirror';
};

#-----------------------------------------------------------------------------

subtest 'Invalid response from Stratopan' => sub {
    
    my $target = Pinto::Target->new('PkgA~2');

    set_up_test_ua($target, 200, '[this is not json}');

    my $t = Pinto::Tester->new(init_args => {sources => $sources});
    $t->run_ok(Pull => {targets => $target});
    $t->registration_ok('AUTHOR/Dist-2/PkgA~2');
    
    $t->stderr_like(qr/Invalid response from Stratopan/);

    my $dist = $t->get_distribution(target => $target);
    like $dist->source, $mirror_rx, 'Target was pulled from mirror';
};

#-----------------------------------------------------------------------------

subtest 'Stratopan has distribution' => sub {

    my $target = Pinto::Target->new('AUTHOR/Dist-1.tar.gz');    
    my $location = { uri => "$stratopan/authors/id/A/AU/AUTHOR/Dist-1.tar.gz" };

    set_up_test_ua($target, 200, [$location]);

    my $t = Pinto::Tester->new(init_args => {sources => $sources});
    $t->run_ok(Pull => {targets => $target});
    $t->registration_ok('AUTHOR/Dist-1/PkgA~1');
    
    my $dist = $t->get_distribution(target => $target);
    like $dist->source, $stratopan_rx, 'Target was pulled from stratopan';
};

#-----------------------------------------------------------------------------

subtest 'Mirror has distribution' => sub {
    
    my $target = Pinto::Target->new('AUTHOR/Dist-2.tar.gz');

    set_up_test_ua($target, 200, []);

    my $t = Pinto::Tester->new(init_args => {sources => $sources});
    $t->run_ok(Pull => {targets => $target});
    $t->registration_ok('AUTHOR/Dist-2/PkgA~2');
    
    my $dist = $t->get_distribution(target => $target);
    like $dist->source, $mirror_rx, 'Target was pulled from mirror';
};

#-----------------------------------------------------------------------------

sub set_up_test_ua {
    my ($target, $status, $content) = @_;

    $content = encode_json($content) if ref $content;

    my $uri = $PINTO_STRATOPAN_LOCATOR_URI->clone;
    $uri->query_form(q => $target);

    my $ua = $Pinto::Globals::UA = Test::LWP::UserAgent->new;
    my $response = HTTP::Response->new($status, undef, undef, $content);

    $ua->map_response(qr/\Q$uri\E/, $response);
    $ua->map_network_response(qr/^file:/);

    return $ua;
}
#-----------------------------------------------------------------------------

done_testing;
