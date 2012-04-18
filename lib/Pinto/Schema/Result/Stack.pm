use utf8;
package Pinto::Schema::Result::Stack;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Pinto::Schema::Result::Stack

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<stack>

=cut

__PACKAGE__->table("stack");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 name

  data_type: 'text'
  is_nullable: 0

=head2 mtime

  data_type: 'integer'
  is_nullable: 0

=head2 description

  data_type: 'text'
  default_value: null
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "name",
  { data_type => "text", is_nullable => 0 },
  "mtime",
  { data_type => "integer", is_nullable => 0 },
  "description",
  { data_type => "text", default_value => \"null", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<name_unique>

=over 4

=item * L</name>

=back

=cut

__PACKAGE__->add_unique_constraint("name_unique", ["name"]);

=head1 RELATIONS

=head2 package_stack_histories

Type: has_many

Related object: L<Pinto::Schema::Result::PackageStackHistory>

=cut

__PACKAGE__->has_many(
  "package_stack_histories",
  "Pinto::Schema::Result::PackageStackHistory",
  { "foreign.stack" => "self.id" },
  { cascade_copy => 0, cascade_delete => 1 },
);

=head2 packages_stack

Type: has_many

Related object: L<Pinto::Schema::Result::PackageStack>

=cut

__PACKAGE__->has_many(
  "packages_stack",
  "Pinto::Schema::Result::PackageStack",
  { "foreign.stack" => "self.id" },
  { cascade_copy => 0, cascade_delete => 1 },
);


# Created by DBIx::Class::Schema::Loader v0.07015 @ 2012-04-17 22:37:23
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:uR7vptgVMmlXRcMVOMJF/g

#----------------------------------------------------------------------------------------

# ABSTRACT: Represents a named set of Packages

#----------------------------------------------------------------------------------------

# VERSION

#----------------------------------------------------------------------------------------

use String::Format;

use overload ( '""'     => 'to_string' );

#----------------------------------------------------------------------------------------
# Schema::Loader does not create many-to-many relationships for us.  So we
# must create them by hand here...

__PACKAGE__->many_to_many( packages => 'package_stack', 'package' );

#------------------------------------------------------------------------------

sub new {
    my ($class, $attrs) = @_;

    $attrs->{mtime} ||= time;

    return $class->SUPER::new($attrs);
}

#----------------------------------------------------------------------------------------

sub to_string {
    my ($self, $format) = @_;

    my %fspec = (
          'k' => sub { $self->name()                                          },
          'e' => sub { $self->description()                                   },
          'u' => sub { $self->mtime()                                         },
          'U' => sub { scalar localtime $self->mtime()                        },
    );

    $format ||= $self->default_format();
    return String::Format::stringf($format, %fspec);
}

#----------------------------------------------------------------------------------------

sub default_format {
    my ($self) = @_;

    return '%k';
}

#----------------------------------------------------------------------------------------
1;

__END__

