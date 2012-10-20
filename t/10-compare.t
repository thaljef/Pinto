#!perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

use Pinto::Tester::Util qw(make_dist_obj make_pkg_obj);

#------------------------------------------------------------------------------
# Test package specification is as follows:
#
#   dist_name-dist_mtime/pkg_name-pkg_version
#
# For example:
#
#   Foo-1/Bar-0.3
#
# Means pacakge Bar version 0.3 in dist Foo with mtime 1
#------------------------------------------------------------------------------

package_compare_ok( 'Dist-1/Pkg-undef', 'Dist-1/Pkg-1'       );
package_compare_ok( 'Dist-1/Pkg-0',     'Dist-1/Pkg-1'       );
package_compare_ok( 'Dist-1/Pkg-1',     'Dist-1/Pkg-2'       );
package_compare_ok( 'Dist-1/Pkg-1',     'Dist-2/Pkg-1'       );
package_compare_ok( 'Dist-1/Pkg-1.1.1', 'Dist-1/Pkg-1.1.2'   );
package_compare_ok( 'Dist-1/Pkg-1.1.1', 'Dist-2/Pkg-1.1.1'   );


# Exceptions
throws_ok { package_compare_ok( 'Dist-1/Foo-1-0', 'Dist-1/Bar-1-1' ) }
  qr/packages with different names/;

throws_ok { package_compare_ok( 'Dist-1/Foo-1-1', 'Dist-1/Foo-1-1' ) }
  qr/Unable to determine ordering/;

throws_ok { package_compare_ok( 'Dist-1/Foo-1-0', 'Dist-1/Foo-1-0' ) }
  qr/Unable to determine ordering/;

throws_ok { _make_pkg( 'Dist-1/Foo-1-0' ) <=> 1.2  }
  qr/Can only compare Pinto::Schema::Result::Package objects/;

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
my $id = 0;

sub _make_pkg {
    my ($spec) = @_;
    my ($dist_spec, $pkg_spec) = split '/', $spec;

    my ($dist_name, $mtime)  = split '-', $dist_spec;
    my ($pkg_name, $pkg_version, $is_local) = split '-', $pkg_spec;

    my $dist = make_dist_obj(
          author   => 'AUTHOR',
          archive  => "$dist_name-0.00.tar.gz",
          mtime    => $mtime || 0,
          id       => $id++,
    );

    my $pkg = make_pkg_obj(
          name         => $pkg_name,
          version      => $pkg_version,
          distribution => $dist,
          id           => $id++,
    );

    return $pkg;
}

#------------------------------------------------------------------------------

done_testing;
