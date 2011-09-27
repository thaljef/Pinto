package Pinto::Comparator;

use strict;
use warnings;

use Pinto::Exceptions qw(throw_error);

#-------------------------------------------------------------------------------

# VERSION

#-------------------------------------------------------------------------------

sub compare_packages {
    my ($class, $pkg_a, $pkg_b) = @_;

    throw_error "Cannot compare packages with different names"
        if $pkg_a->name() ne $pkg_b->name();

    throw_error "Cannot compare development distribution $pkg_a"
        if $pkg_a->is_devel();

    throw_error "Cannot compare development distribution $pkg_b"
        if $pkg_b->is_devel();

    my $r =   ( $pkg_a->is_local()          <=> $pkg_b->is_local()          )
           || ( $pkg_a->version_numeric()   <=> $pkg_b->version_numeric()   );

    my ($dist_a, $dist_b) = ( $pkg_a->distribution(), $pkg_b->distribution() );
    $r ||= $class->compare_distributions($dist_a, $dist_b);

    throw_error "Unable to compare $pkg_a and $pkg_b" if not $r;

    return $r;
};

#-------------------------------------------------------------------------------

sub compare_distributions {
    my ($class, $dist_a, $dist_b) = @_;

    throw_error "Cannot compare distributions with different names"
        if $dist_a->name() ne $dist_b->name();

    throw_error "Cannot compare development distribution $dist_a"
        if $dist_a->is_devel();

    throw_error "Cannot compare development distribution $dist_b"
        if $dist_b->is_devel();

    my $r =   ( $dist_a->is_local()         <=> $dist_b->is_local()        )
           || ( $dist_a->version_numeric()  <=> $dist_b->version_numeric() );

    throw_error "Unable to compare $dist_a and dist_b" if not $r;

    return $r;
}

#-------------------------------------------------------------------------------

1;
