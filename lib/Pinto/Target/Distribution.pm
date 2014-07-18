# ABSTRACT: Specifies a distribution by author and archive

package Pinto::Target::Distribution;

use Moose;
use MooseX::MarkAsMethods ( autoclean => 1 );
use MooseX::Types::Moose qw(ArrayRef Str);

use Pinto::Types qw(AuthorID);
use Pinto::Util qw(throw author_dir);

use overload ( '""' => 'to_string' );

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

has author => (
    is       => 'ro',
    isa      => AuthorID,
    coerce   => 1,
    required => 1,
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
    my $orig  = shift;
    my $class = shift;

    my @args = @_;
    if ( @args == 1 and not ref $args[0] ) {
        my @path_parts = split m{/+}x, $args[0];

        my $author  = shift @path_parts;    # First element
        my $archive = pop @path_parts;      # Last element
        my $subdirs = [@path_parts];        # Everything else

        throw "Invalid distribution target: $args[0]"
            if not( $author and $archive );

        @args = ( author => $author, subdirs => $subdirs, archive => $archive );
    }

    return $class->$orig(@args);
};

#------------------------------------------------------------------------------

=method path()

Returns the canonical string form of this DistributionSpec, which is suitable
for constructing a URI.

=cut

sub path {
    my ($self) = @_;

    my $author_dir = author_dir($self->author);
    my @subdirs    = @{ $self->subdirs };
    my $archive    = $self->archive;

    return join '/', $author_dir, @subdirs, $archive;
}

#------------------------------------------------------------------------------

=method to_string

Serializes this Target to its string form.  This method is called whenever the
Target is evaluated in string context.

=cut

sub to_string {
    my ($self) = @_;

    my $author  = $self->author;
    my @subdirs = @{ $self->subdirs };
    my $archive = $self->archive;

    return join '/', $author, @subdirs, $archive;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------
1;

__END__

