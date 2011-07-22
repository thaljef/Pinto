package Pinto::Package;

# ABSTRACT: Represents a single record in the 02packages.details.txt file

use Moose;
use Path::Class::File;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

has 'name'   => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has 'version' => (
    is        => 'ro',
    isa       => 'Str',
    required  => 1,
);

has 'file'    => (
    is        => 'ro',
    isa       => 'Str',
    required  => 1,
);

has 'author'  => (
    is        => 'ro',
    isa       => 'Str',
    lazy      => 1,
    init_arg  => undef,
    default   => sub { $_[0]->native_file()->dir()->dir_list(2, 1) },
);

has 'native_file' => (
    is            => 'ro',
    isa           => 'Path::Class::File',
    lazy          => 1,
    init_arg      => undef,
    default       => sub { Path::Class::File->new( $_[0]->file() ) },
);

#------------------------------------------------------------------------------

# TODO: Declare subtype for the 'file' attribute and coerce it from a
# Path::Class::File to a string that always looks like a Unix path.

#------------------------------------------------------------------------------

sub to_string {
    my ($self) = @_;
    my $fw = 38 - length $self->version();
    $fw = length $self->name() if $fw < length $self->name();
    return sprintf "%-${fw}s %s  %s", $self->name(), $self->version(), $self->file();
}

#------------------------------------------------------------------------------

1;

__END__
