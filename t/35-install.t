#!perl

use strict;
use warnings;

use Test::More;
use Test::File;
use Test::Exception;

use Path::Class qw(dir);
use File::Which qw(which);

use Pinto::Tester;
use Pinto::Tester::Util qw(make_dist_archive);

#------------------------------------------------------------------------------

skip_all('cpanm required for install tests') unless which('cpanm');

#------------------------------------------------------------------------------

warn "You will see some messages from cpanm, don't be alarmed...\n";

#------------------------------------------------------------------------------

my $t = Pinto::Tester->new;
$t->populate('JOHN/DistA-1=PkgA-1~PkgB-1,PkgC-1');
$t->populate('PAUL/DistB-1=PkgB-1~PkgD-2');
$t->populate('MARK/DistC-1=PkgC-1');
$t->populate('MARK/DistC-2=PkgC-2,PkgD-2');

#------------------------------------------------------------------------------

{

  my $buffer = '';
  my $sandbox = File::Temp->newdir;
  my $p5_dir = dir($sandbox, qw(lib perl5));
  my %cpanm_opts = (cpanm_options => {q => undef, L => $sandbox->dirname});
  $t->run_ok('Install' => {targets => ['PkgA'], %cpanm_opts, out => \$buffer});
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

  my $buffer = '';
  my $sandbox = File::Temp->newdir;
  my $p5_dir = dir($sandbox, qw(lib perl5));
  my %cpanm_opts = (cpanm_options => {q => undef, L => $sandbox->dirname});
  $t->run_ok('Install' => {targets => ['PkgC'], stack => 'dev', %cpanm_opts, out => \$buffer});

  file_exists_ok($p5_dir->file('PkgC.pm'));


  # Try installing a dist that isn't on the stack
  $t->run_throws_ok('Install' => {targets => ['PkgA'], stack => 'dev', %cpanm_opts},
                   qr/Installation failed/);
}

#------------------------------------------------------------------------------

done_testing;

