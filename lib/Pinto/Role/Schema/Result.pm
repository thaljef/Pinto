# ABSTRACT: Attributes and methods for all Schema::Result objects

package Pinto::Role::Schema::Result;

use Moose::Role;
use MooseX::MarkAsMethods (autoclean => 1);

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

has repo  => (
   is       => 'ro',
   isa      => 'Pinto::Repository',
   default  => sub { $_[0]->result_source->schema->repo },
   init_arg => undef,
   weak_ref => 1,
   lazy     => 1,
);

#------------------------------------------------------------------------------

sub refresh {
    my ($self) = @_;

    $self->discard_changes;

    return $self;
}

#------------------------------------------------------------------------------

sub refresh_column {
    my ($self, $column) = @_;

    $self->mark_column_dirty($column);

    return $self->get_column($column);
}

#------------------------------------------------------------------------------

1;

__END__

=head1 DESCRIPTION

This role adds a L<Pinto::Repository> attributes.  It should only be
applied to L<Pinto::Schema::Result> subclasses, as it will reach into
the underlying L<Pinto::Schema> object to get at the repo.

This gives us a back door for injecting additional attributes into
L<Pinto::Schema::Result> objects, since those are usually created by
L<DBIx::Class> and we don't have control over the construction
process.

=cut
