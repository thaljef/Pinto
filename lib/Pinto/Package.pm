package Pinto::Package;

# ABSTRACT: Represents a single record in the 02packages.details.txt file

use Moose;

use Path::Class qw();

use Pinto::Util;

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

=attr author()

Returns the author of this Package.  If it wasn't given explicitly,
the author is extracted from the path to the file this Package lives
in.  For example, the author of F<J/JO/JOHN/Foo-Bar-1.2.tar.gz> will
be C<JOHN>.

=cut

has 'author'  => (
    is        => 'ro',
    isa       => 'Str',
    required  => 1,
);

#------------------------------------------------------------------------------

sub BUILDARGS {
    my ($class, %args)  = @_;

    if (my $author = $args{author}) {

      # If the author argument is specified, then assume we are
      # constructing this Package manually (i.e. like by reading
      # metadata about some distribution).  In this case, the file
      # attribute can be determined from the author and the name of
      # the distribution.

      my $author_dir = Pinto::Util::directory_for_author($author);
      my $basename   = Path::Class::file( $args{file} )->basename();

      $args{file}  = Path::Class::file($author_dir, $basename)
        ->as_foreign('Unix')->stringify();
    }
    else {

      # But if the author argument is not specified, then assume we
      # are constructing this Package from data in an index.  In this
      # case, the author can be determined from the file.  I'm doing
      # this by hand (instead of using Path::Class or File::Spec) for
      # performance reasons.  There's going to be a lot of these
      # objects!

      $args{author} = (split '/', $args{file})[2]
        or die "Unable to extract author from $args{file}";
    }

    return \%args;
}

#------------------------------------------------------------------------------

# TODO: Declare subtype for the 'file' attribute and coerce it from a
# Path::Class::File to a string that always looks like a Unix path.

#------------------------------------------------------------------------------

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

__PACKAGE__->meta()->make_immutable();

#------------------------------------------------------------------------------

1;

__END__

=head1 DESCRIPTION

This is a private module for internal use only.  There is nothing for
you to see here (yet).

=cut
