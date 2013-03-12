# ABSTRACT: List known stacks in the repository

package Pinto::Action::Stacks;

use Moose;
use MooseX::Types::Moose qw(Str);
use MooseX::MarkAsMethods (autoclean => 1);

use List::Util qw(max);

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

extends 'Pinto::Action';

#------------------------------------------------------------------------------

with 'Pinto::Role::Colorable';

#------------------------------------------------------------------------------

has format => (
    is      => 'ro',
    isa     => Str,
);

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    my @stacks = sort {$a cmp $b} $self->repo->get_all_stacks;

	my $max_name = max(map { length($_->name) } @stacks)           || 0;
	my $max_user = max(map { length($_->head->username) } @stacks) || 0;

	my $format = $self->format || "%M%L %-${max_name}k  %u  %-{$max_user}j  %i: %{40}T";

	for my $stack (@stacks) {
		my $string = $stack->to_string($format);

		my $color =   $stack->is_default ? $self->color_1 
		            : $stack->is_locked  ? $self->color_3 : undef;

		$string = $self->colorize_with_color($string, $color);
		$self->say( $string ); 
	}


    return $self->result;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------

1;

__END__
