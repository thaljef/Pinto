# ABSTRACT: List the contents of a stack

package Pinto::Action::List;

use Moose;
use MooseX::Types::Moose qw(Undef HashRef Str Bool);

use Pinto::Types qw(Author StackName StackAt StackDefault);

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

extends qw( Pinto::Action );

#------------------------------------------------------------------------------

with qw( Pinto::Role::Reporter );

#------------------------------------------------------------------------------

has stack => (
    is        => 'ro',
    isa       => StackName | StackAt | StackDefault,
    default   => undef,
    coerce    => 1,
);


has pinned => (
    is     => 'ro',
    isa    => Bool,
);


has author => (
    is     => 'ro',
    isa    => Author,
    coerce => 1,
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
    default   => "%m%s%y %-40n %12v  %a/%f\n",
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
        $where->{'distribution.author'} = $author;
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

    if (defined $stk_name and $stk_name eq '@') {
        # If listing all stacks, then include the stack name
        # in the listing, unless a custom format has been given
        $format = $self->has_format ? $self->format
                                    : "%m%s%y %-12k %-40n %12v  %p\n";
    }
    else{
        # Otherwise, list only the named stack, falling back to
        # the default stack if no stack was named at all.
        my $stack = $self->repos->get_stack(name => $stk_name);
        $where->{'stack.name'} = $stack->name;
        $format = $self->format;
    }

    # HACK: The 'stack' table should also be prefetched here (not
    # joined).  But in DBIx-Class 0.08198, the prefetch feature seems
    # to be broken.  See RT #78456 for details.  In the meantime, this
    # seems to work around the problem, although it requires an extra
    # trip to the database if we need the stack name in the listing.
    my $attrs = { order_by => [ qw(me.package_name me.package_version me.distribution_path) ],
                  prefetch => {package => 'distribution'},
                  join     => 'stack' };

    my $rs = $self->repos->db->select_registrations($where, $attrs);
    $DB::single = 1;
    while( my $registration = $rs->next ) {
        print { $self->out } $registration->to_string($format);
    }

    return $self->result;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------

1;

__END__
