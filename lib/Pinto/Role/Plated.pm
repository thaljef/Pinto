# ABSTRACT: Something that has chrome plating

package Pinto::Role::Plated;

use Moose::Role;
use MooseX::MarkAsMethods ( autoclean => 1 );

#-----------------------------------------------------------------------------

# VERSION

#-----------------------------------------------------------------------------

has chrome => (
    is       => 'ro',
    isa      => 'Pinto::Chrome',
    handles  => [qw(show info notice warning error)],
    required => 1,
);

#-----------------------------------------------------------------------------
1;

__END__
