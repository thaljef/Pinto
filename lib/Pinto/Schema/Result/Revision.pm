use utf8;
package Pinto::Schema::Result::Revision;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Pinto::Schema::Result::Revision

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<revision>

=cut

__PACKAGE__->table("revision");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 number

  data_type: 'integer'
  is_nullable: 0

=head2 stack

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 message

  data_type: 'text'
  is_nullable: 0

=head2 username

  data_type: 'text'
  is_nullable: 0

=head2 ctime

  data_type: 'integer'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "number",
  { data_type => "integer", is_nullable => 0 },
  "stack",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "message",
  { data_type => "text", is_nullable => 0 },
  "username",
  { data_type => "text", is_nullable => 0 },
  "ctime",
  { data_type => "integer", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 package_stack_histories

Type: has_many

Related object: L<Pinto::Schema::Result::PackageStackHistory>

=cut

__PACKAGE__->has_many(
  "package_stack_histories",
  "Pinto::Schema::Result::PackageStackHistory",
  { "foreign.revision" => "self.id" },
  { cascade_copy => 0, cascade_delete => 1 },
);

=head2 stack

Type: belongs_to

Related object: L<Pinto::Schema::Result::Stack>

=cut

__PACKAGE__->belongs_to(
  "stack",
  "Pinto::Schema::Result::Stack",
  { id => "stack" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07015 @ 2012-04-25 09:25:23
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:WkPUVMjdFjNbyH0IjceHuQ

#-------------------------------------------------------------------------------

# ABSTRACT: Identifies a set of changes to the repository

#-------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

sub new {
    my ($class, $attrs) = @_;

    $attrs->{ctime}    ||= time;
    $attrs->{username} ||= $ENV{USER};              # TODO: maybe mandatory?
    $attrs->{message}  ||= 'No message was given';  # TODO: maybe no default?

    my $self = $class->SUPER::new($attrs);
    $self->number( $self->last_number + 1 );

    return $self;
}

#------------------------------------------------------------------------------

sub last_number {
    my ($self) = @_;

    my $where = {stack => $self->stack->id};

    return $self->result_source->resultset->search($where)->count;
}

#------------------------------------------------------------------------------

1;

__END__
