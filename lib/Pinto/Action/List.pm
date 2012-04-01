package Pinto::Action::List;

# ABSTRACT: An action for listing contents of a repository

use Moose;

use Carp qw(croak);

use MooseX::Types::Moose qw(Str Maybe Bool HashRef);
use Pinto::Types qw(IO);

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------
# ISA

extends 'Pinto::Action';

#------------------------------------------------------------------------------

has out => (
    is      => 'ro',
    isa     => IO,
    coerce  => 1,
    default => sub { [fileno(STDOUT), '>'] },
);


has format => (
    is      => 'ro',
    isa     => Str,
    default => '',
);


has pinned => (
    is     => 'ro',
    isa    => Bool,
);


has index => (
    is     => 'ro',
    isa    => Str,
);


has packages => (
    is     => 'ro',
    isa    => Str,
);


has distributions => (
    is     => 'ro',
    isa    => Str,
);


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

override execute => sub {
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
};

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#------------------------------------------------------------------------------

1;

__END__
