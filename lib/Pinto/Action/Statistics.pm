package Pinto::Action::Statistics;

# ABSTRACT: Report statistics about the repository

use Moose;

use Pinto::Statistics;
use Pinto::Types qw(IO);

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------
# ISA

extends 'Pinto::Action';

#------------------------------------------------------------------------------
# Attributes

has out => (
    is      => 'ro',
    isa     => IO,
    coerce  => 1,
    default => sub { [fileno(STDOUT), '>'] },
);

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    my $stats = Pinto::Statistics->new( db => $self->repos->db() );
    print { $self->out() } $stats->to_formatted_string();

    return 0;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#------------------------------------------------------------------------------

1;

__END__
