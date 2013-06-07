#!perl

use strict;
use warnings;

use Test::More;
use Test::File;
use Test::Exception;
use Path::Class qw(dir);

use lib 'tlib';
use Pinto::Tester;
use Pinto::Tester::Util qw(make_dist_archive has_cpanm $MINIMUM_CPANM_VERSION);

#------------------------------------------------------------------------------

plan skip_all => "Need cpanm $MINIMUM_CPANM_VERSION or newer" 
    unless has_cpanm($MINIMUM_CPANM_VERSION);

#------------------------------------------------------------------------------

warn "You will see some messages from cpanm, don't be alarmed...\n";

#------------------------------------------------------------------------------

my $t = Pinto::Tester->new;
$t->populate('JOHN/DistA-1 = PkgA~1 & PkgB~1,PkgC~1');
$t->populate('PAUL/DistB-1 = PkgB~1 & PkgD~2');
$t->populate('MARK/DistC-1 = PkgC~1');
$t->populate('MARK/DistC-2 = PkgC~2,PkgD~2');

#------------------------------------------------------------------------------

subtest install_from_default_stack => sub {

    my $sandbox = File::Temp->newdir;
    my $p5_dir = dir($sandbox, qw(lib perl5));
    my %cpanm_opts = (cpanm_options => {q => undef, L => $sandbox->dirname});
    $t->run_ok(Install => {targets => ['PkgA'], %cpanm_opts});

    file_exists_ok($p5_dir->file('PkgA.pm'));
    file_exists_ok($p5_dir->file('PkgB.pm'));
    file_exists_ok($p5_dir->file('PkgC.pm'));
    file_exists_ok($p5_dir->file('PkgD.pm'));
};

#------------------------------------------------------------------------------

subtest install_from_named_stack => sub {

    $t->run_ok('New'  => {stack => 'dev'} );
    $t->run_ok('Pull' => {targets => 'PkgA', stack => 'dev'});

    my $sandbox = File::Temp->newdir;
    my $p5_dir = dir($sandbox, qw(lib perl5));
    my %cpanm_opts = (cpanm_options => {q => undef, L => $sandbox->dirname});
    $t->run_ok(Install => {targets => ['PkgA'], stack => 'dev', %cpanm_opts});

    file_exists_ok($p5_dir->file('PkgA.pm'));
    file_exists_ok($p5_dir->file('PkgB.pm'));
    file_exists_ok($p5_dir->file('PkgC.pm'));
    file_exists_ok($p5_dir->file('PkgD.pm'));
};

#------------------------------------------------------------------------------

subtest missing_target => sub {

    my $sandbox = File::Temp->newdir;
    my $p5_dir = dir($sandbox, qw(lib perl5));
    my %cpanm_opts = (cpanm_options => {q => undef, L => $sandbox->dirname});

    $t->run_throws_ok(Install => {targets => ['PkgZ'], %cpanm_opts}, qr/Installation failed/);
};

#------------------------------------------------------------------------------

subtest unusual_author_id => sub {

    # Versions of cpanm before 1.6916 could not handle short author ids or those
    # that contained numbers and hyphens.  But miyagawa agreed to support them
    # since they are allowed by CPAN::DistnameInfo.

    my $t = Pinto::Tester->new;
    $t->populate('FOO-22/DistA-1 = PkgA~1');
    $t->populate('FO/DistB-1 = PkgB~1');

    my $sandbox = File::Temp->newdir;
    my $p5_dir = dir($sandbox, qw(lib perl5));
    my %cpanm_opts = (cpanm_options => {q => undef, L => $sandbox->dirname});
    $t->run_ok(Install => {targets => ['PkgA'], %cpanm_opts});
    $t->run_ok(Install => {targets => ['PkgB'], %cpanm_opts});

    file_exists_ok($p5_dir->file('PkgA.pm'));
    file_exists_ok($p5_dir->file('PkgB.pm'));
};

#------------------------------------------------------------------------------
done_testing;

