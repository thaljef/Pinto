#!perl

use strict;
use warnings;

use Test::More (tests => 9);
use Test::Exception;

#------------------------------------------------------------------------------
# Pinto::ComparatorTester is defined below

Pinto::ComparatorTester->import('package_compare_ok');

#------------------------------------------------------------------------------
# Args for each test package are:       [ pkg_version, dist_version, is_local ]

package_compare_ok( [1,1,0], [2,1,0], );

package_compare_ok( [1,1,1], [2,1,1], );

package_compare_ok( [1,1,0], [1,1,1], );

package_compare_ok( [2,1,0], [1,1,1], );

package_compare_ok( [1,1,0], [1,2,0], );

package_compare_ok( [1,2,0], [1,1,1], );

package_compare_ok( [1,1,1], [1,2,1], );

dies_ok { package_compare_ok( [1,1,0], [1,1,0] ) }
  'Comparing identical foreign packages/dists should raise exception';

dies_ok { package_compare_ok( [1,1,1], [1,1,1] ) }
  'Comparing identical local packages/dists should raise exception';

#===============================================================================

package Pinto::ComparatorTester;

use base 'Test::Builder::Module';

use Pinto::Schema;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

our @EXPORT = qw(package_compare_ok);
my $TB      = __PACKAGE__->builder();

#------------------------------------------------------------------------------

sub package_compare_ok {
    my ($pkg1, $pkg2, $detail) = @_;
    my $name    = sprintf "Package A sorts before package B: %s", $detail || '';
    my $format  = "pkg_ver: %s, dist_ver: %s, is_local: %s";
    $TB->is_num( make_pkg($pkg1) <=> make_pkg($pkg2), -1, $name )
      or $TB->diag( sprintf "A: $format \nB: $format", @{ $pkg1 }, @{ $pkg2 } );
}

#------------------------------------------------------------------------------

sub make_pkg {
    my ($pkg_version, $dist_version, $is_local, $pkg_id) = @{ shift() };

    my $dist = Pinto::Schema->resultset('Distribution')->new_result(
        {
          path     => "A/AU/AUTHOR/Foo-$dist_version.tar.gz",
          origin   => $is_local ? undef : 'REMOTE',
        }
    );


    my $pkg = Pinto::Schema->resultset('Package')->new_result(
        {
          name         => 'Foo',
          version      => $pkg_version,
          package_id   => $pkg_id,
          distribution => $dist,
        }
    );

    return $pkg;
}

#------------------------------------------------------------------------------
