#!perl

use strict;
use warnings;

use Path::Class;
use FindBin qw($Bin);
use lib dir($Bin, 'lib')->stringify();

use Test::More (tests => 11);
use Test::Exception;

use Pinto::Tester::Util qw(make_dist make_pkg);

#------------------------------------------------------------------------------
# Args for each test package are:       [ pkg_version, dist_version, is_local ]

package_compare_ok( [1,1,0], [2,1,0], );

package_compare_ok( [1,1,1], [2,1,1], );

package_compare_ok( [1,1,0], [1,1,1], );

package_compare_ok( [2,1,0], [1,1,1], );

package_compare_ok( [1,1,0], [1,2,0], );

package_compare_ok( [1,2,0], [1,1,1], );

package_compare_ok( [1,1,1], [1,2,1], );

dies_ok { package_compare_ok( ['1.0_1',1,1], [1,1,1] ) }
  'Comparing a devel package should raise exception';

dies_ok { package_compare_ok( [1,'1.0_1',1], [1,1,1] ) }
  'Comparing a devel dist should raise exception';

dies_ok { package_compare_ok( [1,1,0], [1,1,0] ) }
  'Comparing identical foreign packages/dists should raise exception';

dies_ok { package_compare_ok( [1,1,1], [1,1,1] ) }
  'Comparing identical local packages/dists should raise exception';

#===============================================================================

sub package_compare_ok {
    my ($pkg1, $pkg2, $detail) = @_;
    my $name    = sprintf "Package A sorts before package B: %s", $detail || '';
    my $format  = "pkg_ver: %s, dist_ver: %s, is_local: %s";

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    is( _make_pkg($pkg1) <=> _make_pkg($pkg2), -1, $name )
        or diag( sprintf "A: $format \nB: $format", @{ $pkg1 }, @{ $pkg2 } );
}

#------------------------------------------------------------------------------

sub _make_pkg {
    my ($pkg_version, $dist_version, $is_local) = @{ shift() };

    my $dist = make_dist(
          path     => "A/AU/AUTHOR/Foo-$dist_version.tar.gz",
          origin   => $is_local ? undef : 'FOREIGN',
    );

    my $pkg = make_pkg(
          name         => 'Foo',
          version      => $pkg_version,
          distribution => $dist,
    );

    return $pkg;
}

#------------------------------------------------------------------------------
