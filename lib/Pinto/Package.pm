package Pinto::Package;

use Moose;
use MooseX::Types::Path::Class;

use Carp;

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
    isa       => 'Path::Class::File',
    required  => 1,
    coerce    => 1,
);

#------------------------------------------------------------------------------

sub author {
    my ($self) = @_;
    my $file = $self->file();
    my $author = eval { $file->dir()->dir_list(2, 1) };
    croak "Unable to determine author from $file: $@" if $@;
    return $author;
}

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
