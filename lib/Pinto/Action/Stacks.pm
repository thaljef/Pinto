# ABSTRACT: List known stacks in the repository

package Pinto::Action::Stacks;

use Moose;
use MooseX::StrictConstructor;
use MooseX::Types::Moose qw(Str);
use MooseX::MarkAsMethods ( autoclean => 1 );

use List::Util qw(max);

use Pinto::Constants qw(:color);

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

extends 'Pinto::Action';

#------------------------------------------------------------------------------

has format => (
    is  => 'ro',
    isa => Str,
);

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    my @stacks = sort { $a cmp $b } $self->repo->get_all_stacks;

    my $max_name = max( map { length( $_->name ) } @stacks )           || 0;
    my $max_user = max( map { length( $_->head->username ) } @stacks ) || 0;

    my $format = $self->format || "%M%L %-${max_name}k  %u  %-{$max_user}j  %i: %{40}T";

    for my $stack (@stacks) {
        my $string = $stack->to_string($format);

        my $color =
              $stack->is_default ? $PINTO_PALETTE_COLOR_0
            : $stack->is_locked  ? $PINTO_PALETTE_COLOR_2
            :                      undef;

        $self->show( $string, { color => $color } );
    }

    return $self->result;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------

1;

__END__
