# ABSTRACT: Locate targets using Stratopan services

package Pinto::Locator::Stratopan;

use Moose;
use MooseX::StrictConstructor;
use MooseX::MarkAsMethods ( autoclean => 1 );

#-----------------------------------------------------------------------------

# VERSION

#-----------------------------------------------------------------------------

extends qw(Pinto::Locator);

#-----------------------------------------------------------------------------

sub locate_package {}

#-----------------------------------------------------------------------------

sub locate_distribution {}

#-----------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#-----------------------------------------------------------------------------
1;

__END__