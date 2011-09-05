package Pinto::Schema::Result::Author;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Pinto::Schema::Result::Author

=cut

__PACKAGE__->table("author");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 name

  data_type: 'text'
  is_nullable: 1

=head2 email

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "name",
  { data_type => "text", is_nullable => 1 },
  "email",
  { data_type => "text", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 distributions

Type: has_many

Related object: L<Pinto::Schema::Result::Distribution>

=cut

__PACKAGE__->has_many(
  "distributions",
  "Pinto::Schema::Result::Distribution",
  { "foreign.author" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-09-04 17:03:04
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:apPjJUcgoziY7YLcwvEMFg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
