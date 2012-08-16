# ABSTRACT: List known stacks in the repository

package Pinto::Action::Stacks;

use Moose;
use MooseX::Types::Moose qw(Str);

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

extends 'Pinto::Action';

#------------------------------------------------------------------------------

has format => (
    is      => 'ro',
    isa     => Str,
    default => "%M %-16k %-16j %U\n",
);

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    my $attrs = { order_by => 'name' };
    my @stacks = $self->repos->db->select_stacks(undef, $attrs)->all;

    for my $stack ( @stacks ) {
        print { $self->out } $stack->to_string($self->format);
    }

    return $self->result;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------

1;

__END__
