use strict;
use warnings;

use Pinto;
use Pinto::Config;

use Data::Dumper;

my $cfg = Pinto::Config->new();
my $pinto = Pinto->new(config => $cfg);
$pinto->upgrade();

print Dumper $pinto;
