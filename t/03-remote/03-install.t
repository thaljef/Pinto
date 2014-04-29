#!perl

use strict;
use warnings;

use Test::More;
use Test::File;
use Test::Exception;
use File::Temp;
use Path::Class qw(dir);
use Capture::Tiny qw(capture_stderr);

use Pinto::Remote;

use lib 't/lib';
use Pinto::Server::Tester;
use Pinto::Constants qw($PINTO_MINIMUM_CPANM_VERSION);
use Pinto::Tester::Util qw(has_cpanm);

#------------------------------------------------------------------------------

plan skip_all => "Need cpanm $PINTO_MINIMUM_CPANM_VERSION or newer"
    unless has_cpanm($PINTO_MINIMUM_CPANM_VERSION);

#------------------------------------------------------------------------------

my $t = Pinto::Server::Tester->new->start_server;
plan skip_all => "Can't open connection to $t" unless $t->can_connect;

$t->populate('JOHN/DistA-1 = PkgA~1 & PkgB~1');
$t->populate('PAUL/DistB-1 = PkgB~1 & PkgC~1');
$t->populate('MARK/DistC-1 = PkgC~1');

#------------------------------------------------------------------------------
subtest 'Install from default stack' => sub {

    my $sandbox    = File::Temp->newdir;
    my $p5_dir     = dir( $sandbox, qw(lib perl5) );
    my %cpanm_opts = ( cpanm_options => { q => undef, L => $sandbox->dirname } );
    my $remote     = Pinto::Remote->new( root => $t->server_url );

    my $stderr = capture_stderr {
        $remote->run( Install => ( targets => ['PkgA'], %cpanm_opts ) );
    };

    file_exists_ok( $p5_dir->file('PkgA.pm') );
    file_exists_ok( $p5_dir->file('PkgB.pm') );
    file_exists_ok( $p5_dir->file('PkgC.pm') );
};

#------------------------------------------------------------------------------

subtest 'Install from named stack' => sub {

    $t->run_ok( 'New' => { stack => 'dev' } );
    $t->run_ok( 'Pull' => { targets => 'PkgA', stack => 'dev' } );

    my $sandbox    = File::Temp->newdir;
    my $p5_dir     = dir( $sandbox, qw(lib perl5) );
    my %cpanm_opts = ( cpanm_options => { q => undef, L => $sandbox->dirname } );
    my $remote     = Pinto::Remote->new( root => $t->server_url );

    my $stderr = capture_stderr {
        $remote->run( Install => ( targets => ['PkgA'], stack => 'dev', %cpanm_opts ) );
    };

    file_exists_ok( $p5_dir->file('PkgA.pm') );
    file_exists_ok( $p5_dir->file('PkgB.pm') );
    file_exists_ok( $p5_dir->file('PkgC.pm') );
};

#------------------------------------------------------------------------------

subtest 'Install a missing target' => sub {

    my $sandbox    = File::Temp->newdir;
    my $p5_dir     = dir( $sandbox, qw(lib perl5) );
    my %cpanm_opts = ( cpanm_options => { q => undef, L => $sandbox->dirname } );
    my $remote     = Pinto::Remote->new( root => $t->server_url );

    my $stderr = capture_stderr {
        throws_ok { $remote->run( Install => { targets => ['PkgZ'], %cpanm_opts } ) } qr/Installation failed/;
    };
};

#------------------------------------------------------------------------------

subtest 'Install a dist with an unusual author id' => sub {

    # Versions of cpanm before 1.6916 could not handle short author ids or those
    # that contained numbers and hyphens.  But miyagawa agreed to support them
    # since they are allowed by CPAN::DistnameInfo.

    my $t = Pinto::Server::Tester->new->start_server;
    $t->populate('FOO-22/DistA-1 = PkgA~1');
    $t->populate('FO/DistB-1 = PkgB~1');

    my $sandbox    = File::Temp->newdir;
    my $p5_dir     = dir( $sandbox, qw(lib perl5) );
    my %cpanm_opts = ( cpanm_options => { q => undef, L => $sandbox->dirname } );
    my $remote     = Pinto::Remote->new( root => $t->server_url );

    my $stderr = capture_stderr {
        $remote->run( Install => ( targets => ['FOO-22/DistA-1.tar.gz'], %cpanm_opts ) );
        $remote->run( Install => ( targets => ['FO/DistB-1.tar.gz'], %cpanm_opts ) );
    };

    file_exists_ok( $p5_dir->file('PkgA.pm') );
    file_exists_ok( $p5_dir->file('PkgB.pm') );
};

#------------------------------------------------------------------------------

done_testing;

