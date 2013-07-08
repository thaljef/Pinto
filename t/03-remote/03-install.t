#!perl

use strict;
use warnings;

use Test::More;
use Test::File;
use Test::Exception;
use Path::Class qw(dir);
use Capture::Tiny qw(capture_stderr);

use Pinto::Remote;

use lib 't/lib';
use Pinto::Server::Tester;
use Pinto::Tester::Util qw(make_dist_archive has_cpanm $MINIMUM_CPANM_VERSION);

#------------------------------------------------------------------------------

plan skip_all => "Need cpanm $MINIMUM_CPANM_VERSION or newer"
    unless has_cpanm($MINIMUM_CPANM_VERSION);

#------------------------------------------------------------------------------

my $t = Pinto::Server::Tester->new->start_server;
$t->populate('JOHN/DistA-1 = PkgA~1 & PkgB~1,PkgC~1');
$t->populate('PAUL/DistB-1 = PkgB~1 & PkgD~2');
$t->populate('MARK/DistC-1 = PkgC~1');
$t->populate('MARK/DistC-2 = PkgC~2,PkgD~2');

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
    file_exists_ok( $p5_dir->file('PkgD.pm') );
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
    file_exists_ok( $p5_dir->file('PkgD.pm') );
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
        $remote->run( Install => ( targets => ['PkgA'], %cpanm_opts ) );
        $remote->run( Install => ( targets => ['PkgB'], %cpanm_opts ) );
    };

    file_exists_ok( $p5_dir->file('PkgA.pm') );
    file_exists_ok( $p5_dir->file('PkgB.pm') );
};

#------------------------------------------------------------------------------

done_testing;

