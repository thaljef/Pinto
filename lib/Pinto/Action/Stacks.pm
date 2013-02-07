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

	my $max_name = max map { length($_->name) } @stacks;
	my $max_user = max map { length($_->head->username) } @stacks;

	my $format = $self->format || "%M%L %-${max_name}k  %U  %-{$max_user}J  %i: %t";

	for my $stack (@stacks) {
		my $string = $stack->to_string($format);

		if ($stack->is_default) {
			$string = $self->color_1 . $string . $self->color_0;
		}
		elsif ($stack->is_locked) {
			$string = $self->color_3 . $string . $self->color_0;
		}

		$self->say( $string ); 
	}


    return $self->result;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------

1;

__END__
