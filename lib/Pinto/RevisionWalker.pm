# ABSTRACT: Iterates through revision history

package Pinto::RevisionWalker;

use Moose;
use MooseX::StrictConstructor;
use MooseX::Types::Moose qw(ArrayRef);
use MooseX::MarkAsMethods ( autoclean => 1 );

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------
# TODO: Rethink this API.  Do we need start?  Can we just use queue?  What
# about filtering, or walking forward?  Sort chronolobical or topological?

has start => (
    is       => 'ro',
    isa      => 'Pinto::Schema::Result::Revision',
    required => 1,
);

has queue => (
    isa     => ArrayRef,
    traits  => [qw(Array)],
    handles => { enqueue => 'push', dequeue => 'shift' },
    default => sub { [ $_[0]->start ] },
    lazy    => 1,
);

#------------------------------------------------------------------------------

sub next {
    my ($self) = @_;

    my $next = $self->dequeue;

    return if not $next;
    return if $next->is_root;

    $self->enqueue( $next->parents );

    return $next;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#-------------------------------------------------------------------------------
1;

__END__
