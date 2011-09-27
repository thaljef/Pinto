#!perl

use strict;
use warnings;

use Path::Class;
use FindBin qw($Bin);
use lib dir($Bin, 'lib')->stringify();

use Test::More (tests => 9);

use Pinto::Package::Tester;

#------------------------------------------------------------------------------

package_compare_ok( [1,1,0], [2,1,0], );

package_compare_ok( [1,1,1], [2,1,1], );

package_compare_ok( [1,1,0], [1,1,1], );

package_compare_ok( [2,1,0], [1,1,1], );

package_compare_ok( [1,1,0], [1,1,0], ); # same

package_compare_ok( [1,1,1], [1,1,1], ); # same

package_compare_ok( [1,1,0], [1,2,0], ); # dists

package_compare_ok( [1,2,0], [1,1,1], );

package_compare_ok( [1,1,1], [1,2,1], ); # dists

#------------------------------------------------------------------------------


