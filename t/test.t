use strict;
use warnings;

use Pinto;
use Pinto::Config;

use Data::Dumper;
use File::Temp;
use Path::Class;
use FindBin qw($Bin);

my $cfg    = Pinto::Config->new();
$cfg->{_}->{local} = dir($Bin, 'tmp')->absolute();
$cfg->{_}->{remote} = 'file://' . dir(shift)->absolute();

my $pinto  = Pinto->new(config => $cfg);
$pinto->upgrade();

$pinto->add(file => shift);
