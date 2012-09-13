use utf8;
package Pinto::Schema::Result::RegistrationHistory;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Pinto::Schema::Result::RegistrationHistory

=cut

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

=head1 TABLE: C<registration_history>

=cut

__PACKAGE__->table("registration_history");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 stack

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 package

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 is_pinned

  data_type: 'integer'
  is_nullable: 0

=head2 created_in_revision

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 deleted_in_revision

  data_type: 'integer'
  default_value: null
  is_foreign_key: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "stack",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "package",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "is_pinned",
  { data_type => "integer", is_nullable => 0 },
  "created_in_revision",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "deleted_in_revision",
  {
    data_type      => "integer",
    default_value  => \"null",
    is_foreign_key => 1,
    is_nullable    => 1,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 created_in_revision

Type: belongs_to

Related object: L<Pinto::Schema::Result::Revision>

=cut

__PACKAGE__->belongs_to(
  "created_in_revision",
  "Pinto::Schema::Result::Revision",
  { id => "created_in_revision" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 deleted_in_revision

Type: belongs_to

Related object: L<Pinto::Schema::Result::Revision>

=cut

__PACKAGE__->belongs_to(
  "deleted_in_revision",
  "Pinto::Schema::Result::Revision",
  { id => "deleted_in_revision" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

=head2 package

Type: belongs_to

Related object: L<Pinto::Schema::Result::Package>

=cut

__PACKAGE__->belongs_to(
  "package",
  "Pinto::Schema::Result::Package",
  { id => "package" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
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

=head1 L<Moose> ROLES APPLIED

=over 4

=item * L<Pinto::Role::Schema::Result>

=back

=cut


with 'Pinto::Role::Schema::Result';


# Created by DBIx::Class::Schema::Loader v0.07025 @ 2012-09-12 19:37:39
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:8xGz9pVcGt7SIQ3i6rR/3w


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
