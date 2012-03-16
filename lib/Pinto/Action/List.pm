package Pinto::Action::List;

# ABSTRACT: List the contents of a repository

use Moose;

use Carp qw(croak);

use MooseX::Types::Moose qw(Str HashRef);
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
    default => "%y%s%m %-40n %-12v %p\n",
);


has where => (
    is      => 'ro',
    isa     => HashRef,
    default => sub { {} },
);

#------------------------------------------------------------------------------

override execute => sub {
    my ($self) = @_;

    my $where = $self->where();
    $where->{'stack.name'} ||= 'default';

    if (not $self->repos->get_stack( name => $where->{'stack.name'} )) {
        $self->whine("No such stack named $where->{'stack.name'}");
        return 1;
    }

    my $attrs = { order_by => [ qw(package.name package.version package.distribution.path) ],
                  prefetch => [ 'pin', 'stack', { 'package' => 'distribution' } ] };

    my $rs = $self->repos->db->select_package_stacks($where, $attrs);

    my $format = $self->format();
    while( my $package_stack = $rs->next() ) {
        print { $self->out() } $package_stack->to_string($format);
    }

    return 0;
};

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#------------------------------------------------------------------------------

1;

__END__
