# ABSTRACT: Iterates through distribution prerequisites

package Pinto::RevisionWalker;

use Moose;
use MooseX::Types::Moose qw(ArrayRef);
use MooseX::MarkAsMethods (autoclean => 1);

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------
# TODO: Rethink this API.  Do we need start?  Can we just use queue?  What
# about filtering, or walking forward?  Sort chronolobical or topological?

has start => (
	is       => 'ro',
	isa      => 'Pinto::Schema::Result::Kommit',
	required => 1,
);


has queue => (
    isa      => ArrayRef,
    traits   => [ qw(Array) ],
    handles  => {push => 'push', shift => 'shift'},
    default  => sub { [ $_[0]->start, $_[0]->start->parents ] },
    lazy     => 1,
);

#------------------------------------------------------------------------------

sub next {
  my ($self) = @_;

    my $next = $self->shift;

    return if not $next;
    return if $next->is_root;

    $self->push($next->parents);

    return $next;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#-------------------------------------------------------------------------------
1;

__END__
