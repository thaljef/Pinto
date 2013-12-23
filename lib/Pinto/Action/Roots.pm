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

sub execute {
    my ($self) = @_;

    my $stack = $self->repo->get_stack($self->stack);
    my @dists = $stack->head->distributions->all;
    my %is_prereq_dist;
    my %cache;

   # We could probably apply a bit of graph theory here and
   # use a faster algorithm for finding the roots of a DAG. 

    for my $dist ( @dists ) {
        next if $is_prereq_dist{$dist};
        for my $prereq ($dist->prerequisites) {
            my %args = (spec => $prereq->as_spec, cache => \%cache);
            next unless my $prereq_dist = $stack->get_distribution(%args);
            $is_prereq_dist{$prereq_dist}++;
        }
    }

    my @roots  = grep { ! $is_prereq_dist{$_} } @dists;
    my @output = sort map { $_->to_string($self->format) } @roots;
    $self->show($_) for @output;

    return $self->result;
} 

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------

1;

__END__
