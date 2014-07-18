# ABSTRACT: Create Spec objects from strings

package Pinto::Target;

use strict;
use warnings;

use Class::Load;

use Pinto::Exception;

#-------------------------------------------------------------------------------

# VERSION

#-------------------------------------------------------------------------------

=method new( $string )

[Class Method] Returns either a L<Pinto::Target::Distribution> or
L<Pinto::Target::Package> object constructed from the given C<$string>.

=cut

sub new {
    my ( $class, $arg ) = @_;

    my $type = ref $arg;
    my $target_class;

    if ( not $type ) {

        $target_class =
            ( $arg =~ m{/}x )
            ? 'Pinto::Target::Distribution'
            : 'Pinto::Target::Package';
    }
    elsif ( ref $arg eq 'HASH' ) {

        $target_class =
            ( exists $arg->{author} )
            ? 'Pinto::Target::Distribution'
            : 'Pinto::Target::Package';
    }
    else {

        # I would just use throw() here, but I need to avoid
        # creating a circular dependency between this package,
        # Pinto::Types and Pinto::Util.

        my $message = "Don't know how to make target from $arg";
        Pinto::Exception->throw( message => $message );

    }

    Class::Load::load_class($target_class);
    return $target_class->new($arg);
}

#-------------------------------------------------------------------------------
1;

__END__
