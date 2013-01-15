# ABSTRACT: Base class for all Mergers

package Pinto::Merger::FastForward;

use Moose;
use MooseX::Types::Moose qw(ArrayRef);

use Pinto::Exception qw(throw);

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
	my @kommits    = ( $new_head, $new_head->ancestors );

	for my $kommit ( @kommits ) {
		$self->debug("Applying $kommit");
		$kommit->redo(stack => $to_stack);
	}

	$to_stack->set_head( $new_head );
	$self->info("Head of $to_stack is now $new_head");

	return;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------
1;

__END__
