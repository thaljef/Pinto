# ABSTRACT: List known stacks in the repository

package Pinto::Action::Stack::List;

use Moose;
use MooseX::Types::Moose qw(Str HashRef);

use List::Util qw(max);

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

extends 'Pinto::Action';

#------------------------------------------------------------------------------

with qw( Pinto::Role::Interface::Action::Stack::List );

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    my $attrs = { order_by => 'name' };
    my @stacks = $self->repos->db->select_stacks(undef, $attrs)->all;
    my $longest = max( map { length $_->name } @stacks );

    my $format = $self->format || "%${longest}k: %e\n";
    for my $stack ( @stacks ) {
        print { $self->out } $stack->to_string($format);
    }

    return $self->result;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#------------------------------------------------------------------------------

1;

__END__
