# ABSTRACT: Specifies a distribution by author and path fragments

package Pinto::DistributionSpec;

use Moose;
use MooseX::MarkAsMethods (autoclean => 1);
use MooseX::Types::Moose qw(ArrayRef Str);

use Pinto::Types qw(AuthorID);
use Pinto::Util qw(throw);

use overload ('""' => 'to_string');

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------


has author => (
    is       => 'ro',
    isa      => AuthorID,
    required => 1,
);


has author_canonical => (
    is       => 'ro',
    isa      => Str,
    init_arg => undef,
    default  => sub { uc $_[0]->author },
    lazy     => 1,
);


has archive => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);


has subdirs => (
    is      => 'ro',
    isa     => ArrayRef[Str],
    default => sub { [] },
);

#------------------------------------------------------------------------------

around BUILDARGS => sub {
    my $orig = shift;
    my $class = shift;

    my @args = @_;
    if (@args == 1 and not ref $args[0]) {
        my @path_parts = split m{/+}x, $args[0];

        my $author   = shift @path_parts;  # First element
        my $archive  = pop @path_parts;    # Last element
        my $subdirs  = [ @path_parts ];    # Everything else

        throw "Invalid distribution spec: $args[0]"
            if not ($author and $archive);

        @args = (author => $author, subdirs => $subdirs, archive => $archive);
    }

    return $class->$orig(@args);
};


#------------------------------------------------------------------------------

=method path()

Returns the canonical string form of this DistributionSpec, which is
suitable for constructing a URI.

=cut

sub path {
    my ($self) = @_;

    my $author   = $self->author_canonical;
    my @subdirs  = @{ $self->subdirs };
    my $archive  = $self->archive;

    return join '/', substr($author, 0, 1),
                     substr($author, 0, 2),
                     $author,
                     @subdirs,
                     $archive;
}

#------------------------------------------------------------------------------

=method to_string

This method is called when the DistributionSpec is evaluated in string
context.  Returns the same result as the C<path> method.

=cut

sub to_string {
    my ($self) = @_;

    my $author   = $self->author;
    my @subdirs  = @{ $self->subdirs };
    my $archive  = $self->archive;

    return join '/', $author,
                     @subdirs,
                     $archive;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------
1;

__END__

