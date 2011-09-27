package Pinto::Package::Tester;

# ABSTRACT: A class for testing a Pinto packages

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
1;

__END__
