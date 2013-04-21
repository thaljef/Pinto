# ABSTRACT: Base class for Pinto exceptions

package Pinto::Exception;

use Moose;
use MooseX::MarkAsMethods (autoclean => 1);

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

extends qw(Throwable::Error);

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------
1;

__END__
