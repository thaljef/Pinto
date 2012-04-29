use utf8;
package Pinto::Schema::Result::StackProperty;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Pinto::Schema::Result::StackProperty

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<stack_property>

=cut

__PACKAGE__->table("stack_property");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 stack

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 name

  data_type: 'text'
  is_nullable: 0

=head2 value

  data_type: 'text'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "stack",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "name",
  { data_type => "text", is_nullable => 0 },
  "value",
  { data_type => "text", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<stack_name_unique>

=over 4

=item * L</stack>

=item * L</name>

=back

=cut

__PACKAGE__->add_unique_constraint("stack_name_unique", ["stack", "name"]);

=head1 RELATIONS

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


# Created by DBIx::Class::Schema::Loader v0.07015 @ 2012-04-28 19:02:20
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:951EbH/NfeYWIA5DNRIU3Q


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
