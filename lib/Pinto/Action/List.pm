package Pinto::Action::List;

# ABSTRACT: An abstract action for listing packages in a repository

use Moose;
use Pinto::Types 0.017 qw(IO);

extends 'Pinto::Action';

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

has out => (
    is      => 'ro',
    isa     => IO,
    coerce  => 1,
    default => sub { [fileno(STDOUT), '>'] },
);

#------------------------------------------------------------------------------

override execute => sub {
    my ($self) = @_;
    die 'Abstract method!';
};

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#------------------------------------------------------------------------------

1;

__END__
