# ABSTRACT: Base class for all Mergers

package Pinto::Merger::FastForward;

use Moose;

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

extends qw( Pinto::Merger );

#------------------------------------------------------------------------------

sub merge {
	my ($self) = @_;

	my $to_stack   = $self->to_stack;
	my $from_stack = $self->from_stack;
	my $new_head   = $self->from_stack->head;

	$self->info("Head of $to_stack is now $new_head");
	$to_stack->set_head( kommit => $new_head );
	$to_stack->write_index;

	return;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------
1;

__END__
