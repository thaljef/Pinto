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
use Pinto::Tester::Util qw(has_cpanm $MINIMUM_CPANM_VERSION);

#------------------------------------------------------------------------------

plan skip_all => "Need cpanm $MINIMUM_CPANM_VERSION or newer" 
    unless has_cpanm($MINIMUM_CPANM_VERSION);

#------------------------------------------------------------------------------

my $upstream = Pinto::Tester->new;
$upstream->populate('JOHN/DistA-1 = PkgA~1');

my $local = Pinto::Tester->new(init_args => {sources => $upstream->stack_url});
$local->populate('MARK/DistB-1 = PkgB~1 & PkgA~1');

#------------------------------------------------------------------------------

subtest 'Install while pulling upstream prereqs' => sub {

  my $sandbox = File::Temp->newdir;
  my $p5_dir = dir($sandbox, qw(lib perl5));
  my %cpanm_opts = (cpanm_options => {q => undef, L => $sandbox->dirname});

  my $stderr = capture_stderr {
  	$local->run_ok(Install => {targets => ['PkgB'], %cpanm_opts, do_pull =>1});
  };

  file_exists_ok($p5_dir->file('PkgA.pm'));
  file_exists_ok($p5_dir->file('PkgB.pm'));
};

#------------------------------------------------------------------------------

done_testing;

