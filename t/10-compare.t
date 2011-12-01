#!perl

use strict;
use warnings;

use Test::Exception;
use Test::More (tests => 22);

use Pinto::Tester::Util qw(make_dist make_pkg);

#------------------------------------------------------------------------------
# Test package specification is as follows:
#
#   dist_name-dist_mtime/pkg_name-pkg_version-source
#
# where source = 1 (local) or 0 (foreign)
#
# For example:
#
#   Foo-1/Bar-0.3-1
#
# Means local pacakge Bar version 0.3 in dist Foo with mtime 1
#------------------------------------------------------------------------------

# Comparing locals to locals
package_compare_ok( 'Dist-1/Pkg-undef-1', 'Dist-1/Pkg-1-1'   );
package_compare_ok( 'Dist-1/Pkg-0-1',     'Dist-1/Pkg-1-1'   );
package_compare_ok( 'Dist-1/Pkg-1-1',     'Dist-1/Pkg-2-1'   );
package_compare_ok( 'Dist-1/Pkg-1-1',     'Dist-2/Pkg-1-1'   );
package_compare_ok( 'Dist-1/Pkg-1.1.1-1', 'Dist-1/Pkg-1.1.2-1'   );
package_compare_ok( 'Dist-1/Pkg-1.1.1-1', 'Dist-2/Pkg-1.1.1-1'   );


# Comparing foreign to foreign
package_compare_ok( 'Dist-1/Pkg-undef-0', 'Dist-1/Pkg-1-0'   );
package_compare_ok( 'Dist-1/Pkg-0-0',     'Dist-1/Pkg-1-0'   );
package_compare_ok( 'Dist-1/Pkg-1-0',     'Dist-1/Pkg-2-0'   );
package_compare_ok( 'Dist-1/Pkg-1-0',     'Dist-2/Pkg-1-0'   );
package_compare_ok( 'Dist-1/Pkg-1.1.1-0', 'Dist-1/Pkg-1.1.2-0'   );
package_compare_ok( 'Dist-1/Pkg-1.1.1-0', 'Dist-2/Pkg-1.1.1-0'   );


# Comparing foreign to local
package_compare_ok( 'Dist-1/Pkg-1-0',     'Dist-1/Pkg-undef-1' );
package_compare_ok( 'Dist-1/Pkg-1-0',     'Dist-1/Pkg-0-1'     );
package_compare_ok( 'Dist-1/Pkg-2-0',     'Dist-1/Pkg-1-1'     );
package_compare_ok( 'Dist-2/Pkg-1-0',     'Dist-1/Pkg-1-1'     );
package_compare_ok( 'Dist-1/Pkg-1.1.2-0', 'Dist-1/Pkg-1.1.1-1' );
package_compare_ok( 'Dist-2/Pkg-1.1.1-0', 'Dist-1/Pkg-1.1.1-1' );


# Exceptions
throws_ok { package_compare_ok( 'Dist-1/Foo-1-0', 'Dist-1/Bar-1-1' ) }
  qr/packages with different names/;

throws_ok { package_compare_ok( 'Dist-1/Foo-1-1', 'Dist-1/Foo-1-1' ) }
  qr/Unable to determine ordering/;

throws_ok { package_compare_ok( 'Dist-1/Foo-1-0', 'Dist-1/Foo-1-0' ) }
  qr/Unable to determine ordering/;

throws_ok { _make_pkg( 'Dist-1/Foo-1-0' ) <=> 1.2  }
  qr/Can only compare Pinto::Package objects/;

#===============================================================================

sub package_compare_ok {
    my ($spec_A, $spec_B, $test_name) = @_;

    $test_name = "Package A sorts before package B";
    my ($pkg_A, $pkg_B) = map { _make_pkg($_)} ($spec_A, $spec_B);

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my $ok = is( $pkg_A <=> $pkg_B, -1, $test_name );
    diag( "  A: $spec_A \n  B: $spec_B" ) if not $ok;
    return $ok;
}

#------------------------------------------------------------------------------

sub _make_pkg {
    my ($spec) = @_;
    my ($dist_spec, $pkg_spec) = split '/', $spec;

    my ($dist_name, $mtime)  = split '-', $dist_spec;
    my ($pkg_name, $pkg_version, $is_local) = split '-', $pkg_spec;

    my $dist = make_dist(
          path     => "A/AU/AUTHOR/$dist_name-0.00.tar.gz",
          source   => $is_local ? undef : 'FOREIGN',
          mtime    => $mtime || 0,
    );

    my $pkg = make_pkg(
          name         => $pkg_name,
          version      => $pkg_version,
          distribution => $dist,
    );

    return $pkg;
}

#------------------------------------------------------------------------------
