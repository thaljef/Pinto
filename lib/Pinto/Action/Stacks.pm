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
    default => "%M%L %-16k %i %-16J %U",
);

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    for my $stack ( sort {$a cmp $b} $self->repo->get_all_stacks ) {
        $self->say($stack->to_string($self->format));
    }

    return $self->result;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------

1;

__END__
