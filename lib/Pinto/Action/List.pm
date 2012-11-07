# ABSTRACT: List the contents of a stack

package Pinto::Action::List;

use Moose;
use MooseX::Types::Moose qw(HashRef Str Bool);

use Pinto::Types qw(Author StackName StackAll StackDefault StackObject);
use Pinto::Constants qw($PINTO_STACK_NAME_ALL);

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
    default   => "%m%s%y %-40n %12v  %a/%f",
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
    my $format;

    if (defined $stk_name and $stk_name eq $PINTO_STACK_NAME_ALL) {
        # If listing all stacks, then include the stack name
        # in the listing, unless a custom format has been given
        $format = $self->has_format ? $self->format
                                    : "%m%s%y %-12k %-40n %12v  %p";
    }
    else{
        # Otherwise, list only the named stack, falling back to
        # the default stack if no stack was named at all.
        my $stack = $self->repo->get_stack($stk_name);
        $where->{'stack.name'} = $stack->name;
        $format = $self->format;
    }


    my $attrs = {prefetch => ['stack', {package => 'distribution'}],
                 order_by => [ qw(package.name) ] };

    ################################################################

    my $rs = $self->repo->db->select_registrations($where, $attrs);

    while( my $registration = $rs->next ) {
        $self->say($registration->to_string($format));
    }

    return $self->result;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------

1;

__END__
