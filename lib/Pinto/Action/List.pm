# ABSTRACT: List the contents of a stack

package Pinto::Action::List;

use Moose;
use MooseX::Types::Moose qw(HashRef Str Bool);

use Pinto::Types qw(Author StackName StackAll StackDefault StackObject);
use Pinto::Util qw(is_stack_all);

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

extends qw( Pinto::Action );

#------------------------------------------------------------------------------

has stack => (
    is        => 'ro',
    isa       => StackName | StackAll | StackDefault | StackObject,
    default   => undef,
);


has pinned => (
    is     => 'ro',
    isa    => Bool,
);


has author => (
    is     => 'ro',
    isa    => Author,
);


has packages => (
    is     => 'ro',
    isa    => Str,
);


has distributions => (
    is     => 'ro',
    isa    => Str,
);


has format => (
    is        => 'ro',
    isa       => Str,
    default   => "%m%s%y %-40p %12v  %A/%f",
    predicate => 'has_format',
    lazy      => 1,
);


has where => (
    is       => 'ro',
    isa      => HashRef,
    builder  => '_build_where',
    lazy     => 1,
);

#------------------------------------------------------------------------------

sub _build_where {
    my ($self) = @_;

    my $where = {};

    if (my $pkg_name = $self->packages) {
        $where->{'package.name'} = { like => "%$pkg_name%" }
    }

    if (my $dist_name = $self->distributions) {
        $where->{'distribution.archive'} = { like => "%$dist_name%" };
    }

    if (my $author = $self->author) {
        $where->{'distribution.author_canonical'} = uc $author;
    }

    if (my $pinned = $self->pinned) {
        $where->{is_pinned} = 1;
    }

    return $where;
}

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    my $where    = $self->where;
    my $stk_name = $self->stack;

    my @stacks =   is_stack_all($stk_name)
                 ? $self->repo->get_all_stacks
                 : $self->repo->get_stack($stk_name);

    my $attrs = { prefetch => {package => 'distribution'} };

    ##########################################################################

    if (scalar @stacks == 1) {

        # In the common case where we are only listing one stack, we can iterate
        # through the registrations rather than slurping them all into memory.

        $attrs->{order_by} = [ qw(package.name) ];
        my $format = $self->format;
        my $rs = $stacks[0]->head->registrations($where, $attrs);
        while( my $registration = $rs->next ) {
            $self->say($registration->to_string($format));
        }
    }
    else {

        # In the uncommon case where we are listing multiple stacks, we must
        # slurp the registrations for all stacks into memory and then sort
        # them by stack.

        my @tuples = map { my $stack = $_; 
                           map {[$stack => $_]} $stack->head->registrations($where, $attrs) } @stacks;

        my @sorted = sort {    $a->[1]->package_name cmp $b->[1]->package_name 
                            || $a->[0]->name cmp $a->[0]->name } @tuples;
        
        for (@sorted) {
            my $stack        = $_->[0];
            my $registration = $_->[1];
            my $format = $self->has_format ? $self->format : "%m%s%y %-12k %-40p %12v  %A/%f";
            $format = $stack->to_string($format); # Expands the stack-related placeholders
            $self->say($registration->to_string($format));
        }               
    }

    return $self->result;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------

1;

__END__
