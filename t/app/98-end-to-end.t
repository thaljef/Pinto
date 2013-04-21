#!perl

use strict;
use warnings;

use Test::More;
use App::Cmd::Tester;
use File::Which qw(which);

#-------------------------------------------------------------------------------

my $pintod_exe = which('pintod');
plan(skip_all => 'Requires pintod') if not $pintod_exe;

my $has_pinto = eval { require Pinto };
plan(skip_all => 'Requires Pinto') if not $has_pinto;

my $has_pinto_remote = eval { require Pinto::Remote };
plan(skip_all => 'Requires Pinto::Remote') if not $has_pinto_remote;

my $has_pinto_tester = eval { require Pinto::Tester };
plan(skip_all => 'Requires Pinto::Tester') if not $has_pinto_tester;

#-------------------------------------------------------------------------------

plan(skip_all => 'End-to-end tests not written yet');

#-------------------------------------------------------------------------------

done_testing;
