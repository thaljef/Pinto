package Pinto::Role::Loggable;

# ABSTRACT: Something that logs activity

use Moose::Role;

has log => (
    is       => 'ro',
    isa      => 'Pinto::Logger',
    handles  => [qw(debug info warn fatal)],
    required => 1,
);

1;

__END__
