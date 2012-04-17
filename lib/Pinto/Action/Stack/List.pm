package Pinto::Action::Stack::List;

# ABSTRACT: An action for listing stacks

use Moose;

use MooseX::Types::Moose qw(Str HashRef);
use Pinto::Types qw(IO);

use List::Util qw(max);

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
    isa     => 'Maybe[Str]',
);


has where => (
    is      => 'ro',
    isa     => HashRef,
    default => sub { {} },
);

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    my $where = $self->where();
    my $attrs = { order_by => 'name' };

    my @stacks = $self->repos->db->select_stacks($where, $attrs)->all();
    my $longest = max( map { length $_->name() } @stacks );

    my $format = $self->format() || "%${longest}k  %e\n";
    for my $stack ( @stacks ) {
        print { $self->out() } $stack->to_string($format);
    }

    return 0;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#------------------------------------------------------------------------------

1;

__END__
