# ABSTRACT: List the contents of a repository

package Pinto::Action::List;

use Moose;
use MooseX::Types::Moose qw(HashRef);

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

extends qw( Pinto::Action );

#------------------------------------------------------------------------------

with qw( Pinto::Role::Interface::Action::List );

#------------------------------------------------------------------------------

has where => (
    is       => 'ro',
    isa      => HashRef,
    builder  => '_build_where',
    init_arg => undef,
    lazy     => 1,
);

#------------------------------------------------------------------------------

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

sub execute {
    my ($self) = @_;

    my $where = $self->where;

    $self->repos->get_stack( name => $where->{'stack.name'} )
        or $self->fatal("No such stack named $where->{'stack.name'}");

    my $attrs = { order_by => [ qw(package.name package.version package.distribution.path) ],
                  prefetch => [ 'stack', { 'package' => 'distribution' } ] };

    my $rs = $self->repos->db->select_package_stacks($where, $attrs);

    while( my $package_stack = $rs->next ) {
        print { $self->out } $package_stack->to_string($self->format);
    }

    return $self->result;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#------------------------------------------------------------------------------

1;

__END__
