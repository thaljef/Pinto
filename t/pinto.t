#!perl

use strict;
use warnings;

use Test::More (tests => 2);
use File::Temp;

use Pinto;
use Pinto::Config;

my $cfg = Pinto::Config->new();
$cfg->{_}->{local} = File::Temp->new_dir();
$cfg->{_}->{remote} = 'http://cpan.
