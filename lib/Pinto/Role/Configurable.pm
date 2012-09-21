# ABSTRACT: Something that has a configuration

package Pinto::Role::Configurable;

use Moose::Role;

use Pinto::Config;

use namespace::autoclean;

#-----------------------------------------------------------------------------

# VERSION

#-----------------------------------------------------------------------------

has config => (
    is         => 'ro',
    isa        => 'Pinto::Config',
    handles    => [ qw( root root_dir ) ],
    required   => 1,
);

#-----------------------------------------------------------------------------

around BUILDARGS => sub {
    my $orig = shift;
    my $class = shift;

    my $args = $class->$orig(@_);

    $args->{config} ||= Pinto::Config->new( $args );
    return $args;
};

1;

__END__
