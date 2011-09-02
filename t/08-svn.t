#!perl

use strict;
use warnings;

use Test::More (tests => 5);
use Pinto::Util::Svn;
use Data::Dumper;

#------------------------------------------------------------------------------

no warnings 'redefine';
*Pinto::Util::Svn::_svn = sub { my %args = @_; return @{$args{command}} };

#------------------------------------------------------------------------------
# Commit with paths as arguments

my @paths = (1..127);
my @cmd = Pinto::Util::Svn::svn_commit(paths => \@paths);

is(scalar @cmd, 130, 'Command has correct number of args');

#------------------------------------------------------------------------------
# Commit with a target file (when there are lots of arguments)

@paths = (1..128);
@cmd = Pinto::Util::Svn::svn_commit(paths => \@paths);

is(scalar @cmd, 5, 'Command has correct number of args');
is($cmd[3], '--targets', 'Command is using a targets file');

my $targets_file = $cmd[4];
ok(-e $targets_file, 'Targets file exists');

my @targets = $targets_file->slurp();
is(scalar @targets, 128, 'Targets file has correct number of lines');

#------------------------------------------------------------------------------
