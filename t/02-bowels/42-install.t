#!perl

use strict;
use warnings;

use Test::More;
use Test::File;
use Test::Exception;
use Path::Class qw(dir);
use Capture::Tiny qw(capture_stderr);

use lib 't/lib';
use Pinto::Tester;
use Pinto::Tester::Util qw(has_cpanm);
use Pinto::Constants qw($PINTO_MINIMUM_CPANM_VERSION);

#------------------------------------------------------------------------------

plan skip_all => "Need cpanm $PINTO_MINIMUM_CPANM_VERSION or newer"
    unless has_cpanm($PINTO_MINIMUM_CPANM_VERSION);

#------------------------------------------------------------------------------

my $t = Pinto::Tester->new;
$t->populate('JOHN/DistA-1 = PkgA~1 & PkgB~1; PkgC~1');
$t->populate('PAUL/DistB-1 = PkgB~1 & PkgD~2');
$t->populate('MARK/DistC-1 = PkgC~1');
$t->populate('MARK/DistC-2 = PkgC~2; PkgD~2');

#------------------------------------------------------------------------------

subtest 'Install from default stack' => sub {

    my $sandbox    = File::Temp->newdir;
    my $p5_dir     = dir( $sandbox, qw(lib perl5) );
    my %cpanm_opts = ( cpanm_options => { q => undef, L => $sandbox->dirname } );

    my $stderr = capture_stderr {
        $t->run_ok( Install => { targets => ['PkgA'], %cpanm_opts } );
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

    my $stderr = capture_stderr {
        $t->run_ok( Install => { targets => ['PkgA'], stack => 'dev', %cpanm_opts } );
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

    my $stderr = capture_stderr {
        $t->run_throws_ok(
            Install => { targets => ['PkgZ'], %cpanm_opts },
            qr/Installation failed/
        );
    };
};

#------------------------------------------------------------------------------

subtest 'Install target with unusual author ID' => sub {

    # Versions of cpanm before 1.6916 could not handle short author ids or those
    # that contained numbers and hyphens.  But miyagawa agreed to support them
    # since they are allowed by CPAN::DistnameInfo.

    my $t = Pinto::Tester->new;
    $t->populate('FOO-22/DistA-1 = PkgA~1');
    $t->populate('FO/DistB-1 = PkgB~1');

    my $sandbox    = File::Temp->newdir;
    my $p5_dir     = dir( $sandbox, qw(lib perl5) );
    my %cpanm_opts = ( cpanm_options => { q => undef, L => $sandbox->dirname } );

    my $stderr = capture_stderr {
        $t->run_ok( Install => { targets => ['PkgA'], %cpanm_opts } );
        $t->run_ok( Install => { targets => ['PkgB'], %cpanm_opts } );
    };

    file_exists_ok( $p5_dir->file('PkgA.pm') );
    file_exists_ok( $p5_dir->file('PkgB.pm') );
};

#------------------------------------------------------------------------------

subtest 'Install a core module' => sub {

    # The index for a stack contains all the core modules that
    # are in the target_perl_version, even though the repository
    # doesn't actually contain perl itself.  This allows installers
    # to cope with requests to install core modules.

    my $t = Pinto::Tester->new;
    my $sandbox    = File::Temp->newdir;
    my $p5_dir     = dir( $sandbox, qw(lib perl5) );
    my %cpanm_opts = ( cpanm_options => { q => undef, L => $sandbox->dirname } );

    capture_stderr {
        $t->run_ok( Install => { targets => ['strict'], %cpanm_opts } );
    };

    file_not_exists_ok( $p5_dir->file('strict.pm') );

    # Inserting a dual-life module should replace the core one, and
    # cpanm should install it if the version is newer that core.
    $t->populate('AUTHOR/Strict-99 = strict~99');

    capture_stderr {
        $t->run_ok( Install => { targets => ['strict'], %cpanm_opts } );
    };

    file_exists_ok( $p5_dir->file('strict.pm') );
};

#------------------------------------------------------------------------------

# TODO: Install (and maybe pull) target with complex vreq

#------------------------------------------------------------------------------
done_testing;

