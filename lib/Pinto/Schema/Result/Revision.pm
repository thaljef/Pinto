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

=head2 package_stack_history_created_revisions

Type: has_many

Related object: L<Pinto::Schema::Result::PackageStackHistory>

=cut

__PACKAGE__->has_many(
  "package_stack_history_created_revisions",
  "Pinto::Schema::Result::PackageStackHistory",
  { "foreign.created_revision" => "self.id" },
  { cascade_copy => 0, cascade_delete => 1 },
);

=head2 package_stack_history_deleted_revisions

Type: has_many

Related object: L<Pinto::Schema::Result::PackageStackHistory>

=cut

__PACKAGE__->has_many(
  "package_stack_history_deleted_revisions",
  "Pinto::Schema::Result::PackageStackHistory",
  { "foreign.deleted_revision" => "self.id" },
  { cascade_copy => 0, cascade_delete => 1 },
);


# Created by DBIx::Class::Schema::Loader v0.07015 @ 2012-04-17 22:37:23
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:VVz9G8zOj6db5i8BEGj/Zg

#-------------------------------------------------------------------------------

# ABSTRACT: Represents a distribution archive

#-------------------------------------------------------------------------------


#------------------------------------------------------------------------------

sub new {
    my ($class, $attrs) = @_;

    $attrs->{ctime}    ||= time;
    $attrs->{username} ||= $ENV{USER};
    $attrs->{message}  ||= 'No message was given';

    return $class->SUPER::new($attrs);
}


#------------------------------------------------------------------------------

1;

__END__
