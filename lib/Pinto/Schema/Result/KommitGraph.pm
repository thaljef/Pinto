use utf8;
package Pinto::Schema::Result::KommitGraph;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Pinto::Schema::Result::KommitGraph

=cut

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

=head1 TABLE: C<kommit_graph>

=cut

__PACKAGE__->table("kommit_graph");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 depth

  data_type: 'integer'
  is_nullable: 0

=head2 ancestor

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 descendant

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "depth",
  { data_type => "integer", is_nullable => 0 },
  "ancestor",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "descendant",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 ancestor

Type: belongs_to

Related object: L<Pinto::Schema::Result::Kommit>

=cut

__PACKAGE__->belongs_to(
  "ancestor",
  "Pinto::Schema::Result::Kommit",
  { id => "ancestor" },
  { is_deferrable => 0, on_delete => "CASCADE", on_update => "NO ACTION" },
);

=head2 descendant

Type: belongs_to

Related object: L<Pinto::Schema::Result::Kommit>

=cut

__PACKAGE__->belongs_to(
  "descendant",
  "Pinto::Schema::Result::Kommit",
  { id => "descendant" },
  { is_deferrable => 0, on_delete => "CASCADE", on_update => "NO ACTION" },
);

=head1 L<Moose> ROLES APPLIED

=over 4

=item * L<Pinto::Role::Schema::Result>

=back

=cut


with 'Pinto::Role::Schema::Result';


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-01-13 22:05:21
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ViJ/EAgM9Oq2cO+XHfmkvg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
