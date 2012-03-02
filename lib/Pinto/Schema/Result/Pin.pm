use utf8;
package Pinto::Schema::Result::Pin;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Pinto::Schema::Result::Pin

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<pin>

=cut

__PACKAGE__->table("pin");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 ctime

  data_type: 'integer'
  is_nullable: 0

=head2 reason

  data_type: 'text'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "ctime",
  { data_type => "integer", is_nullable => 0 },
  "reason",
  { data_type => "text", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 packages_stack

Type: has_many

Related object: L<Pinto::Schema::Result::PackageStack>

=cut

__PACKAGE__->has_many(
  "packages_stack",
  "Pinto::Schema::Result::PackageStack",
  { "foreign.pin" => "self.id" },
  { cascade_copy => 0, cascade_delete => 1 },
);


# Created by DBIx::Class::Schema::Loader v0.07015 @ 2012-03-01 18:42:22
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:N9evlt2OEnxXQb9QtpgwUw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
