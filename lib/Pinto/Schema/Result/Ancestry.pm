use utf8;

package Pinto::Schema::Result::Ancestry;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Pinto::Schema::Result::Ancestry

=cut

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

=head1 TABLE: C<ancestry>

=cut

__PACKAGE__->table("ancestry");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 parent

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 child

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
    "id",     { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
    "parent", { data_type => "integer", is_foreign_key    => 1, is_nullable => 0 },
    "child",  { data_type => "integer", is_foreign_key    => 1, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 child

Type: belongs_to

Related object: L<Pinto::Schema::Result::Revision>

=cut

__PACKAGE__->belongs_to(
    "child",
    "Pinto::Schema::Result::Revision",
    { id            => "child" },
    { is_deferrable => 0, on_delete => "CASCADE", on_update => "NO ACTION" },
);

=head2 parent

Type: belongs_to

Related object: L<Pinto::Schema::Result::Revision>

=cut

__PACKAGE__->belongs_to(
    "parent",
    "Pinto::Schema::Result::Revision",
    { id            => "parent" },
    { is_deferrable => 0, on_delete => "CASCADE", on_update => "NO ACTION" },
);

=head1 L<Moose> ROLES APPLIED

=over 4

=item * L<Pinto::Role::Schema::Result>

=back

=cut

with 'Pinto::Role::Schema::Result';

# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-02-27 14:20:24
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:NAFcD1cZ00q/UhZ15CEYUg

#-------------------------------------------------------------------------------

# ABSTRACT: Represents the relationship between revisions

#-----------------------------------------------------------------------------

# VERSION

#-----------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#-----------------------------------------------------------------------------
1;

__END__
