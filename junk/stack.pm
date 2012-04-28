# ABSTRACT: Something that has a stack attribute

package Pinto::Role::Attribute::stack;

use Moose::Role;

use Carp;

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

requires qw(repos);

#------------------------------------------------------------------------------

has stack => (
    is       => 'ro',
    isa      => 'Pinto::Schema::Result::Stack',
    writer   => '_set_stack',
    init_arg => undef,
);

#------------------------------------------------------------------------------

sub BUILD {};

before BUILD => sub {
    my ($self, $args) = @_;
    my $stack_name = $args->{stack} || 'default';
    my $stack = $self->repos->get_stack(name => $stack_name);
    confess "No such stack $stack_name" if not $stack;
    $self->_set_stack($stack);
};

#------------------------------------------------------------------------------

1;

__END__
