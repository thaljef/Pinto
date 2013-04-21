# ABSTRACT: Create Spec objects from strings

package Pinto::SpecFactory;

use strict;
use warnings;

use Class::Load;

use Pinto::Util qw(throw); 

#-------------------------------------------------------------------------------

# VERSION

#-------------------------------------------------------------------------------

=method make_spec( $string )

[Class Method] Returns either a L<Pinto::DistributionSpec> or
L<Pinto::PackageSpec> object constructed from the given C<$string>.

=cut


sub make_spec {
    my ($class, $arg) = @_;

    my $type = ref $arg;
    my $spec_class;

    if (not $type) {

      $spec_class = ($arg =~ m{/}x) ? 'Pinto::DistributionSpec'
                                    : 'Pinto::PackageSpec';
    }
    elsif (ref $arg eq 'HASH') {

      $spec_class = (exists $arg->{author}) ? 'Pinto::DistributionSpec'
                                            : 'Pinto::PackageSpec';
    }
    else {

      throw "Don't know how to make spec from $arg";
    }

    Class::Load::load_class($spec_class);
    return $spec_class->new($arg);
}

#-------------------------------------------------------------------------------
1;

__END__
