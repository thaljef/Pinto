# ABSTRACT: Not in use -- will be removed

package Pinto::Schema::Result::RegistrationChange;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

#-----------------------------------------------------------------------------

# VERSION

#-----------------------------------------------------------------------------

__PACKAGE__->table("registration_change");

#-----------------------------------------------------------------------------

1;

__END__
