#!perl

use strict;
use warnings;

use Test::More;
use Test::LWP::UserAgent;

use JSON;
use HTTP::Response;

use Pinto::Target;
use Pinto::Locator::Multiplex;
use Pinto::Constants qw(:stratopan);

use lib 't/lib';
use Pinto::Tester;

#-----------------------------------------------------------------------------
# We create a multiplex locator that uses stratopan and a local repository as
# the upstream sources.  But we will intercept requests to the stratopan
# locator service and supply our own response.  Then we test if the locator
# returns the right location for the target (either stratopan or the mirror). 
#-----------------------------------------------------------------------------

my $stratopan = $PINTO_STRATOPAN_CPAN_URI;
my $mirror    = Pinto::Tester->new->populate('AUTHOR/Dist-2 = PkgA~2');
my @sources   = map { URI->new($_) } ($stratopan, $mirror);

#-----------------------------------------------------------------------------

my $last_warning;
local $SIG{__WARN__} = sub { $last_warning = shift };

#-----------------------------------------------------------------------------

subtest 'Stratopan has package' => sub {
    
    my $stratopan_location = {
        package => 'PkgA', 
        version => '1', 
        uri     => "$stratopan/authors/id/A/AU/AUTHOR/Dist-1.tar.gz",
    };

    my $target = Pinto::Target->new('PkgA');
    my $ua  = build_ua($target, 200, [$stratopan_location]);
    my $mux = build_mux(@sources);
    my $got = $mux->locate(target => $target);
    is_deeply $got, $stratopan_location, 'Located on Stratopan';
};

#-----------------------------------------------------------------------------

subtest 'Mirror has package' => sub {

    my $mirror_location = {
        package => 'PkgA', 
        version => '2', 
        uri     => "$mirror/authors/id/A/AU/AUTHOR/Dist-2.tar.gz",
    };
    
    my $target = Pinto::Target->new('PkgA');
    my $ua  = build_ua($target, 200, []);
    my $mux = build_mux(@sources);
    my $got = $mux->locate(target => $target);
    is_deeply $got, $mirror_location, 'Located on mirror';
};

#-----------------------------------------------------------------------------

subtest 'Nobody has package' => sub {

    my $target = Pinto::Target->new('PkgA==3');
    my $ua  = build_ua($target, 200, []);
    my $mux = build_mux(@sources);
    my $got = $mux->locate(target => $target);
    is $got, undef, 'Not located anywhere';
};

#-----------------------------------------------------------------------------

subtest 'Want latest package (cascade)' => sub {

    my $stratopan_location = {
        package => 'PkgA', 
        version => '1', 
        uri     => "$stratopan/authors/id/A/AU/AUTHOR/Dist-1.tar.gz",
    };

    my $mirror_location = {
        package => 'PkgA', 
        version => '2', 
        uri     => "$mirror/authors/id/A/AU/AUTHOR/Dist-2.tar.gz",
    };

    my $target = Pinto::Target->new('PkgA');
    my $ua  = build_ua($target, 200, [$stratopan_location]);
    my $mux = build_mux(@sources);
    my $got = $mux->locate(target => $target, cascade => 1);
    is_deeply $got, $mirror_location, 'Located on mirror';
};

#-----------------------------------------------------------------------------

subtest 'Stratopan not responding' => sub {

    my $mirror_location = {
        package => 'PkgA', 
        version => '2', 
        uri     => "$mirror/authors/id/A/AU/AUTHOR/Dist-2.tar.gz",
    };
    
    my $target = Pinto::Target->new('PkgA~2');
    my $ua  = build_ua($target, 500);
    my $mux = build_mux(@sources);
    my $got = $mux->locate(target => $target);
    is_deeply $got, $mirror_location, 'Located on mirror';
    like $last_warning, qr/Stratopan is not responding/, 'Got warning';
};

#-----------------------------------------------------------------------------

subtest 'Invalid response from Stratopan' => sub {
    
    my $mirror_location = {
        package => 'PkgA', 
        version => '2', 
        uri     => "$mirror/authors/id/A/AU/AUTHOR/Dist-2.tar.gz",
    };

    my $target = Pinto::Target->new('PkgA~2');
    my $ua  = build_ua($target, 200, '[this is not json}');
    my $mux = build_mux(@sources);
    my $got = $mux->locate(target => $target);
    is_deeply $got, $mirror_location, 'Located on mirror';
    like $last_warning, qr/Invalid response from Stratopan/, 'Got warning';
};

#-----------------------------------------------------------------------------

subtest 'Stratopan has distribution' => sub {

    my $stratopan_location = { 
        uri => "$stratopan/authors/id/A/AU/AUTHOR/Dist-1.tar.gz"
    };

    my $target = Pinto::Target->new('AUTHOR/Dist-1.tar.gz');    
    my $ua = build_ua($target, 200, [$stratopan_location]);
    my $mux = build_mux(@sources);
    my $got = $mux->locate(target => $target);
    is_deeply $got, $stratopan_location, 'Located on Stratopan';
};

#-----------------------------------------------------------------------------

subtest 'Mirror has distribution' => sub {
    
    my $mirror_location = { 
        uri => "$mirror/authors/id/A/AU/AUTHOR/Dist-2.tar.gz"
    };

    my $target = Pinto::Target->new('AUTHOR/Dist-2.tar.gz');
    my $ua = build_ua($target, 200, []);
    my $mux = build_mux(@sources);
    my $got = $mux->locate(target => $target);
    is_deeply $got, $mirror_location, 'Located on mirror';
};

#-----------------------------------------------------------------------------

subtest 'Locate distribution without extension' => sub {
    
    my $mirror_location = { 
        uri => "$mirror/authors/id/A/AU/AUTHOR/Dist-2.tar.gz"
    };

    my $target = Pinto::Target->new('AUTHOR/Dist-2');
    my $ua = build_ua($target, 200, []);
    my $mux = build_mux(@sources);
    my $got = $mux->locate(target => $target);
    is_deeply $got, $mirror_location, 'Located on mirror';
};

#-----------------------------------------------------------------------------

sub build_mux {
    my (@sources) = @_;

    return Pinto::Locator::Multiplex->new->assemble(@sources);
}

#-----------------------------------------------------------------------------

sub build_ua {
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
