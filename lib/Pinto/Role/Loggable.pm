# ABSTRACT: Something that wants to log its activity

package Pinto::Role::Loggable;

use Moose::Role;
use MooseX::MarkAsMethods (autoclean => 1);

use Pinto::Logger;

#-----------------------------------------------------------------------------

# VERSION

#-----------------------------------------------------------------------------

has logger => (
    is         => 'ro',
    isa        => 'Pinto::Logger',
    handles    => [ qw(debug info notice warning error fatal) ],
    required   => 1,
);

#-----------------------------------------------------------------------------

around BUILDARGS => sub {
    my $orig = shift;
    my $class = shift;

    my $args = $class->$orig(@_);

    $args->{logger} = Pinto::Logger->new( %$args ) if not exists $args->{logger};
    return $args;
};

#-----------------------------------------------------------------------------
1;

__END__
