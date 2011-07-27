package Pinto::Package;

# ABSTRACT: Represents a single record in the 02packages.details.txt file

use Moose;

use Path::Class qw();

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

=attr name()

Returns the name of this Package as a string.  For example, C<Foo::Bar>.

=cut

has 'name'   => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

=attr version()

Returns the version of this Package as a string.  This could be a number
or some "version string", such as C<1.5.23>.

=cut

has 'version' => (
    is        => 'ro',
    isa       => 'Str',
    required  => 1,
);

=attr file()

Returns the path to the file this Package lives in, as a string.  The path
is as it appears in the C<02packages.details.txt> file.  So it will be
in Unix format and relative to the F<authors/id> directory.

=cut

has 'file'    => (
    is        => 'ro',
    isa       => 'Str',
    required  => 1,
);

=attr native_file()

Same as the C<file()> method, but returns the path as a
L<Path::Class::File> object that is suitable for your OS.

has 'native_file' => (
    is            => 'ro',
    isa           => 'Path::Class::File',
    lazy          => 1,
    init_arg      => undef,
    default       => sub { Path::Class::File->new( $_[0]->file() ) },
);


=attr author()

Returns the author of this Package.  The author is extracted from the
path to the file this Package lives in.  For example, the author of
F<J/JO/JOHN/Foo-Bar-1.2.tar.gz> will be C<JOHN>.

=cut

has 'author'  => (
    is        => 'ro',
    isa       => 'Str',
    lazy      => 1,
    init_arg  => undef,
    builder   => '__build_author',
);

#------------------------------------------------------------------------------

# TODO: Declare subtype for the 'file' attribute and coerce it from a
# Path::Class::File to a string that always looks like a Unix path.

#------------------------------------------------------------------------------

sub __build_author {
    my ($self) = @_;
    return Path::Class::file( $self->file() )->dir()->dir_list(2, 1);
}

=method to_string()

Returns this Package object in a format that is suitable for writing
to an F<02packages.details.txt> file.

=cut

sub to_string {
    my ($self) = @_;
    my $fw = 38 - length $self->version();
    $fw = length $self->name() if $fw < length $self->name();
    return sprintf "%-${fw}s %s  %s", $self->name(), $self->version(), $self->file();
}

#------------------------------------------------------------------------------

1;

__END__

=head1 DESCRIPTION

This is a private module for internal use only.  There is nothing for
you to see here (yet).

=cut
