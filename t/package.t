use strict;
use warnings;

use Test::More (tests => 1);

use Pinto::Package;

#------------------------------------------------------------------------------

my $package = Pinto::Package->new(name => 'Foo', version => '1.0', file => 'A/AU/AUTH/Foo-1.0.tar.gz');

print $package;

