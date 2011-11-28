package Pinto::Action::List;

# ABSTRACT: An abstract action for listing packages in a repository

use Moose;

use Carp qw(croak);

use MooseX::Types::Moose qw(Bool Str);
use Pinto::Types 0.017 qw(IO);

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

#------------------------------------------------------------------------------

sub package_rs {
    my ($self) = @_;

    my $attrs = { order_by => 'name',  prefetch => 'distribution' };

    return $self->repos->db->get_packages(undef, $attrs);
}

#------------------------------------------------------------------------------

override execute => sub {
    my ($self) = @_;

    my $rs = $self->package_rs();
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
