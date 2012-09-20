# ABSTRACT: Base class for all Actions

package Pinto::Action;

use Moose;
use MooseX::Types::Moose qw(Str);

use Pinto::Result;
use Pinto::Types qw(Io);
use Pinto::Exception;

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

with qw( Pinto::Role::Loggable );

#------------------------------------------------------------------------------


has repos => (
    is       => 'ro',
    isa      => 'Pinto::Repository',
    required => 1,
);


has out => (
    is      => 'ro',
    isa     => Io,
    coerce  => 1,
    default => sub { [fileno(STDOUT), '>'] },
);


has result => (
    is       => 'ro',
    isa      => 'Pinto::Result',
    default  => sub { Pinto::Result->new },
    init_arg => undef,
    lazy     => 1,
);

#------------------------------------------------------------------------------

sub execute { throw 'Abstract method' }

#------------------------------------------------------------------------------

sub say {
    my ($self, $message) = @_;
    return print {$self->out} $message . "\n";
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------
1;

__END__
