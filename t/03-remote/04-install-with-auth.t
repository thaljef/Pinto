#!perl

use strict;
use warnings;

use Test::More;
use Test::File;
use Test::Exception;
use Plack::Test;
use File::Temp;
use Path::Class;
use Capture::Tiny qw(capture_stderr);

use Pinto::Remote;

use lib 't/lib';
use Pinto::Server::Tester;
use Pinto::Tester::Util qw(make_htpasswd_file has_cpanm $MINIMUM_CPANM_VERSION);

#------------------------------------------------------------------------------

plan skip_all => "Need cpanm $MINIMUM_CPANM_VERSION or newer"
    unless has_cpanm($MINIMUM_CPANM_VERSION);

#------------------------------------------------------------------------------
# Setup the server

my $htpasswd = make_htpasswd_file(qw(my_login my_password));
my @auth     = ( qw(--auth backend=Passwd --auth), "path=$htpasswd" );
my $t        = Pinto::Server::Tester->new( pintod_opts => \@auth )->start_server;
$t->populate('JOHN/DistA-1 = PkgA~1 & PkgB~1,PkgC~1');
$t->populate('PAUL/DistB-1 = PkgB~1 & PkgD~2');
$t->populate('MARK/DistC-1 = PkgC~1');
$t->populate('MARK/DistC-2 = PkgC~2,PkgD~2');

#------------------------------------------------------------------------------

subtest 'Remote install succeeds with valid credentials' => sub {

    my %creds = ( username => 'my_login', password => 'my_password' );
    my $remote = Pinto::Remote->new( root => $t->server_url, %creds );

    my $sandbox    = File::Temp->newdir;
    my $p5_dir     = dir( $sandbox, qw(lib perl5) );
    my %cpanm_opts = ( cpanm_options => { q => undef, L => $sandbox->dirname } );

    my $stderr = capture_stderr {
        lives_ok { $remote->run( Install => ( targets => ['PkgA'], %cpanm_opts ) ) } 'install command was successfull';
    };

    file_exists_ok( $p5_dir->file('PkgA.pm') );
    file_exists_ok( $p5_dir->file('PkgB.pm') );
    file_exists_ok( $p5_dir->file('PkgC.pm') );
    file_exists_ok( $p5_dir->file('PkgD.pm') );
};

#------------------------------------------------------------------------------

subtest 'Remote install fails with invalid credentials' => sub {

    my %creds = ( username => 'my_login', password => 'bogus' );
    my $remote = Pinto::Remote->new( root => $t->server_url, %creds );

    my $sandbox    = File::Temp->newdir;
    my $p5_dir     = dir( $sandbox, qw(lib perl5) );
    my %cpanm_opts = ( cpanm_options => { q => undef, L => $sandbox->dirname } );

    my $stderr = capture_stderr {
        throws_ok { $remote->run( Install => ( targets => ['PkgA'], %cpanm_opts ) ) } qr/Installation failed/;
    }
};

#------------------------------------------------------------------------------

subtest 'Remote install fails with no credentials' => sub {

    my %creds = ();
    my $remote = Pinto::Remote->new( root => $t->server_url, %creds );

    my $sandbox    = File::Temp->newdir;
    my $p5_dir     = dir( $sandbox, qw(lib perl5) );
    my %cpanm_opts = ( cpanm_options => { q => undef, L => $sandbox->dirname } );

    my $stderr = capture_stderr {
        throws_ok { $remote->run( Install => ( targets => ['PkgA'], %cpanm_opts ) ) } qr/Installation failed/;
    };
};

#------------------------------------------------------------------------------

done_testing;
