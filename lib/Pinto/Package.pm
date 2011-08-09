package Pinto::Package;

# ABSTRACT: Represents a single record in the 02packages.details.txt file

use Moose;
use MooseX::Types::Moose qw(Str);

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------
# Moose attributes

has 'name'   => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);


has 'version' => (
    is        => 'ro',
    isa       => Str,
    required  => 1,
);


has 'dist'    => (
    is        => 'ro',
    isa       => 'Pinto::Distribution',
    required  => 1,
);

#------------------------------------------------------------------------------

=method to_string()

Returns this Package object in a format that is suitable for writing
to an F<02packages.details.txt> file.

=cut

sub to_string {
    my ($self) = @_;

    my $fw = 38 - length $self->version();
    $fw = length $self->name() if $fw < length $self->name();

    return sprintf "%-${fw}s %s  %s", $self->name(),
                                      $self->version(),
                                      $self->dist->location();
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#------------------------------------------------------------------------------

1;

__END__

=head1 DESCRIPTION

This is a private module for internal use only.  There is nothing for
you to see here (yet).

=cut
