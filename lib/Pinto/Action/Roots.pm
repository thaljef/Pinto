# ABSTRACT: Show the roots of a stack

package Pinto::Action::Roots;

use Moose;
use MooseX::StrictConstructor;
use MooseX::Types::Moose qw(Str);
use MooseX::MarkAsMethods ( autoclean => 1 );

use Pinto::Util qw(whine);
use Pinto::Types qw(StackName StackDefault StackObject);

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

extends qw( Pinto::Action );

#------------------------------------------------------------------------------

has stack => (
    is      => 'ro',
    isa     => StackName | StackDefault | StackObject,
    default => undef,
);

has format => (
    is      => 'ro',
    isa     => Str,
    default => '%a/%f',
    lazy    => 1,
);

#------------------------------------------------------------------------------
# TODO: Refactor this to use the PrerequisiteWalker, and add some cache logic
# to optimize it.  Also, consider moving it to a role (or into the Stack) so
# it can be used in other situations.

sub execute {
    my ($self) = @_;

    my $stack = $self->repo->get_stack($self->stack);
    my @dists = $stack->head->distributions->all;
    my %is_depended_upon;

   # There is lots of room for optimization here.  To start with, we could
   # cache a package -> distribution map so we don't have to make so many
   # trips to the database.  Also, we could probably apply a bit of graph
   # theory here and use an algorithm for finding the roots of a DAG. 

    for my $dist ( @dists ) {
        for my $prereq ($dist->prerequisites) {
            my $dependent_dist = $stack->get_distribution(spec => $prereq->as_spec);
            whine "Prerequisite $prereq seems to be missing for $dist" and next if not $dependent_dist;
            $is_depended_upon{$dependent_dist}++;
        }
    }

    my @roots = grep { ! $is_depended_upon{$_} } @dists;
    $self->show( $_->to_string( $self->format ) ) for @roots;

    return $self->result;
} 

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------

1;

__END__
