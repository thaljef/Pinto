# ABSTRACT: List the contents of a repository

package Pinto::Action::List;

use Moose;
use MooseX::Types::Moose qw(HashRef);

use Pinto::Types qw(StackName);

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

extends qw( Pinto::Action );

#------------------------------------------------------------------------------

with qw( Pinto::Role::Interface::Action::List );

#------------------------------------------------------------------------------

has stack => (
    is      => 'ro',
    isa     => StackName,
    default => 'default',
);


# TODO: Move this into the Attribute role

has '+format' => (
    default  => "%m%s%y %-40n %12v  %p\n",
);

#------------------------------------------------------------------------------
# TODO: Move this builder into the Interface role

sub _build_where {
    my ($self) = @_;

    my $where = { 'stack.name' => $self->stack };

    my $pkg_name = $self->packages();
    $where->{'package.name'} = { like => "%$pkg_name%" } if $pkg_name;

    my $dist_path = $self->distributions();
    $where->{'package.distribution.path'} = { like => "%$dist_path%" } if $dist_path;

    my $pinned = $self->pinned();
    $where->{pin} = { '!=' => undef } if $pinned;

    return $where;
}

#------------------------------------------------------------------------------

sub BUILD {
    my ($self, $args) = @_;

    my $stk_name = $self->stack;
    $self->repos->get_stack(name => $stk_name)
        or $self->fatal("Stack $stk_name does not exist");

    return $self;
}

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    my $where = $self->where;

    if (not $self->repos->get_stack( name => $where->{'stack.name'} )) {
        $self->fatal("No such stack named $where->{'stack.name'}");
    }

    my $attrs = { order_by => [ qw(package.name package.version package.distribution.path) ],
                  prefetch => [ 'stack', { 'package' => 'distribution' } ] };

    my $rs = $self->repos->db->select_package_stacks($where, $attrs);

    my $format = $self->format;
    while( my $package_stack = $rs->next ) {
        print { $self->out } $package_stack->to_string($format);
    }

    return $self->result;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#------------------------------------------------------------------------------

1;

__END__
