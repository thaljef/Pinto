use strict;
use warnings;

use Data::Dumper;
use Path::Class;
use Pinto::Index;


my $index = Pinto::Index->new(source => shift);
print Dumper $index;
