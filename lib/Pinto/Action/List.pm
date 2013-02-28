# ABSTRACT: List the contents of a stack

package Pinto::Action::List;

use Moose;
use MooseX::Types::Moose qw(HashRef Str Bool);

use Pinto::Types qw(AuthorID StackName StackAll StackDefault StackObject);
use Pinto::Constants qw($PINTO_STACK_NAME_ALL);

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

extends qw( Pinto::Action );

#------------------------------------------------------------------------------

with qw( Pinto::Role::Colorable );

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
    isa    => AuthorID,
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
    default   => '%m%s%y %-40p %12v %a/%f',
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
        $where->{'distribution.author'} = uc $author;
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
                                    : '%m%s%y %-12k %-40p %12v %a/%f';
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

    my $rs = $self->repo->db->schema->search_registration($where, $attrs);

    $self->_list($format, $rs);

    return $self->result;
}

#------------------------------------------------------------------------------

sub _list {
    my ($self, $format, $rs) = @_;

    while( my $reg = $rs->next ) {

        my $string = $reg->to_string($format);

        if ($reg->is_pinned) {
            $string = $self->color_3 . $string . $self->color_0;
        }
        elsif ($reg->distribution->is_local) {
            $string = $self->color_1 . $string . $self->color_0;
        }

        $self->say($reg->to_string($string));
    }
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------

1;

__END__
