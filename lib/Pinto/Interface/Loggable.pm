package Pinto::Interface::Loggable;

# ABSTRACT: Something that wants to log its activity

use Moose::Role;

use namespace::autoclean;

#-----------------------------------------------------------------------------

# VERSION

#-----------------------------------------------------------------------------

has logger => (
    is         => 'ro',
    isa        => 'Pinto::Logger',
    handles    => [ qw(debug note info whine fatal) ],
    required   => 1,
);

#-----------------------------------------------------------------------------

around BUILDARGS => sub {
    my $orig = shift;
    my $class = shift;

    my $args = $class->$orig(@_);

    $args->{logger} ||= Pinto::Logger->new( $args );
    return $args;
};

1;

__END__
