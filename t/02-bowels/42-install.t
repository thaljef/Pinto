#!perl

use strict;
use warnings;

use Test::More;
use Test::File;
use Test::Exception;
use Path::Class qw(dir);

use Pinto::Tester;
use Pinto::Tester::Util qw(make_dist_archive has_cpanm);

#------------------------------------------------------------------------------

my $min_cpanm = 1.5013;
plan skip_all => "Need cpanm $min_cpanm or newer" unless has_cpanm($min_cpanm);

#------------------------------------------------------------------------------

warn "You will see some messages from cpanm, don't be alarmed...\n";

#------------------------------------------------------------------------------

my $t = Pinto::Tester->new;
$t->populate('JOHN/DistA-1 = PkgA~1 & PkgB~1,PkgC~1');
$t->populate('PAUL/DistB-1 = PkgB~1 & PkgD~2');
$t->populate('MARK/DistC-1 = PkgC~1');
$t->populate('MARK/DistC-2 = PkgC~2,PkgD~2');

#------------------------------------------------------------------------------

{

  my $sandbox = File::Temp->newdir;
  my $p5_dir = dir($sandbox, qw(lib perl5));
  my %cpanm_opts = (cpanm_options => {q => undef, L => $sandbox->dirname});
  $t->run_ok(Install => {targets => ['PkgA'], %cpanm_opts});
  file_exists_ok($p5_dir->file('PkgA.pm'));
  file_exists_ok($p5_dir->file('PkgB.pm'));
  file_exists_ok($p5_dir->file('PkgC.pm'));
  file_exists_ok($p5_dir->file('PkgD.pm'));
}

#------------------------------------------------------------------------------

{

  # Make a new stack, and pull over one dist
  $t->run_ok('New'  => {stack => 'dev'} );
  $t->run_ok('Pull' => {targets => 'MARK/DistC-1.tar.gz', stack => 'dev'});

  my $sandbox = File::Temp->newdir;
  my $p5_dir = dir($sandbox, qw(lib perl5));
  my %cpanm_opts = (cpanm_options => {q => undef, L => $sandbox->dirname});
  $t->run_ok(Install => {targets => ['PkgC'], stack => 'dev', %cpanm_opts});

  file_exists_ok($p5_dir->file('PkgC.pm'));


  $t->run_throws_ok(Install => {targets => ['PkgA'], stack => 'dev', %cpanm_opts},
                    qr/Installation failed/);
}

#------------------------------------------------------------------------------

done_testing;

