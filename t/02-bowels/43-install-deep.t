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

plan skip_all => "Test does not work on travis-ci" if $ENV{PINTO_RUNNING_UNDER_TRAVIS};

#------------------------------------------------------------------------------

warn "You will see some messages from cpanm, don't be alarmed...\n";

#------------------------------------------------------------------------------

my $upstream = Pinto::Tester->new;
$upstream->populate('JOHN/DistA-1 = PkgA~1');

my $local = Pinto::Tester->new(init_args => {sources => $upstream->stack_url});
$local->populate('MARK/DistB-1 = PkgB~1 & PkgA~1');

#------------------------------------------------------------------------------

{
  my $sandbox = File::Temp->newdir;
  my $p5_dir = dir($sandbox, qw(lib perl5));
  my %cpanm_opts = (cpanm_options => {q => undef, L => $sandbox->dirname});
  $local->run_ok(Install => {targets => ['PkgB'], %cpanm_opts, do_pull =>1});

  file_exists_ok($p5_dir->file('PkgA.pm'));
  file_exists_ok($p5_dir->file('PkgB.pm'));
}

#------------------------------------------------------------------------------

done_testing;

