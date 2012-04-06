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
    is      => 'ro',
    isa     => HashRef,
    builder => '_build_where',
    lazy    => 1,
);

#------------------------------------------------------------------------------

sub _build_where {
    my ($self) = @_;

    my $where = {};

    my $pkg_name = $self->packages();
    $where->{name} = { like => "%$pkg_name%" } if $pkg_name;

    my $dist_path = $self->distributions();
    $where->{path} = { like => "%$dist_path%" } if $dist_path;

    my $index = $self->index();
    $where->{is_latest} = $index ? 1 : undef if defined $index;

    my $pinned = $self->pinned();
    $where->{is_pinned} = $pinned ? 1 : undef if defined $pinned;

    return $where;
}


#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    my $where = $self->where();

    my $attrs = { order_by => [ qw(name version path) ],
                  prefetch => 'distribution' };

    my $rs = $self->repos->db->select_packages($where, $attrs);

    my $format = $self->format();
    while( my $package = $rs->next() ) {
        print { $self->out() } $package->to_formatted_string($format);
    }

    return 0;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#------------------------------------------------------------------------------

1;

__END__
