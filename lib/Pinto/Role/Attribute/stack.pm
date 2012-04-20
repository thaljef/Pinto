# ABSTRACT: Something that has a stack attribute

package Pinto::Role::Attribute::stack;

use Moose::Role;

use Carp;

use Pinto::Types qw(StackName);
use Pinto::Meta::Attribute::Trait::Postable;
use Pinto::Meta::Attribute::Trait::Inflatable;

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

has stack => (
    is       => 'ro',
    isa      => StackName,
    traits   => [ qw(Postable Inflatable) ],
    inflator => '_inflate_stack',
    default  => 'default',
);

#------------------------------------------------------------------------------

sub _inflate_stack {
    my ($self, $stack_name) = @_;
    my $stack = $self->repos->get_stack(name => $stack_name);
    confess "No such stack stack_name" if not $stack;
    return $stack;
}

#------------------------------------------------------------------------------

1;

__END__
