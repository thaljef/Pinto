# ABSTRACT: Attributes and methods for all Schema::Result objects

package Pinto::Role::Schema::Result;

use Moose::Role;

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

has logger  => (
   is       => 'ro',
   isa      => 'Pinto::Logger',
   handles  => [ qw(debug info notice warning error fatal) ],
   default  => sub { $_[0]->result_source->schema->logger },
   lazy     => 1,
);

#------------------------------------------------------------------------------

sub refresh {
    my ($self) = @_;

    $self->discard_changes;

    return $self;
}

#------------------------------------------------------------------------------

1;

__END__

=head1 DESCRIPTION

This role adds a L<Pinto::Logger> attributes.  It should only be
applied to L<Pinto::Schema::Result> subclasses, as it will reach into
the underlying L<Pinto::Schema> object to get at the logger.

This gives us a back door for injecting additional attributes into
L<Pinto::Schema::Result> objects, since those are usually created by
L<DBIx::Class> and we don't have control over the construction
process.

=cut
