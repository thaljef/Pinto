use utf8;
package Pinto::Schema::Result::Stack;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Pinto::Schema::Result::Stack

=cut

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

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

=head2 description

  data_type: 'text'
  is_nullable: 0

=head2 mtime

  data_type: 'integer'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "name",
  { data_type => "text", is_nullable => 0 },
  "description",
  { data_type => "text", is_nullable => 0 },
  "mtime",
  { data_type => "integer", is_nullable => 0 },
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

=head2 registries

Type: has_many

Related object: L<Pinto::Schema::Result::Registry>

=cut

__PACKAGE__->has_many(
  "registries",
  "Pinto::Schema::Result::Registry",
  { "foreign.stack" => "self.id" },
  { cascade_copy => 0, cascade_delete => 1 },
);

=head2 stack_properties

Type: has_many

Related object: L<Pinto::Schema::Result::StackProperty>

=cut

__PACKAGE__->has_many(
  "stack_properties",
  "Pinto::Schema::Result::StackProperty",
  { "foreign.stack" => "self.id" },
  { cascade_copy => 0, cascade_delete => 1 },
);

=head1 L<Moose> ROLES APPLIED

=over 4

=item * L<Pinto::Role::Schema::Result>

=back

=cut


with 'Pinto::Role::Schema::Result';


# Created by DBIx::Class::Schema::Loader v0.07015 @ 2012-04-29 02:10:14
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:tBjUBGsT6o2hBzLiDlqDhg

#-------------------------------------------------------------------------------

# ABSTRACT: Represents a named set of Packages

#-------------------------------------------------------------------------------

# VERSION

#-------------------------------------------------------------------------------

use String::Format;

use overload ( '""'     => 'to_string' );

#-------------------------------------------------------------------------------
# Schema::Loader does not create many-to-many relationships for us.  So we
# must create them by hand here...

__PACKAGE__->many_to_many( packages => 'regsitry', 'package' );

#------------------------------------------------------------------------------

sub new {
    my ($class, $attrs) = @_;

    # Default mtime/description
    $attrs->{mtime} ||= time;
    $attrs->{description} ||= 'no description given';

    return $class->next::method($attrs);
}


#------------------------------------------------------------------------------

sub copy {
    my ($self, $changes) = @_;

    $changes ||= {};

    # Extract properties that are stored separately
    my $old_props = $self->get_properties;
    my $new_props = delete $changes->{properties} || {};
    my $merged_props = { %{$old_props}, %{$new_props} };

    my $guard = $self->result_source->schema->txn_scope_guard;
    my $copy = $self->next::method($changes);
    $copy->set_properties($merged_props);
    $guard->commit;

    return $copy;
}

#------------------------------------------------------------------------------

sub touch {
    my ($self, $time) = @_;
    $self->update( {mtime => $time || time} );
    return $self;
}

#-------------------------------------------------------------------------------

sub get_property {
    my ($self, @prop_names) = @_;

    my %props = %{ $self->get_properties };
    return @props{@prop_names};
}

#-------------------------------------------------------------------------------

sub get_properties {
    my ($self) = @_;

    my @props = $self->search_related('stack_properties')->all;

    return { map { $_->name => $_->value } @props };
}

#-------------------------------------------------------------------------------

sub set_property {
    my ($self, $prop_name, $value) = @_;

    return $self->set_properties( {$prop_name => $value} );
}


#-------------------------------------------------------------------------------

sub set_properties {
    my ($self, $props) = @_;

    my $attrs  = {key => 'stack_name_unique'};
    while (my ($name, $value) = each %{$props}) {
        my $values = {name => $name, value => $value};
        $self->update_or_create_related('stack_properties', $values, $attrs);
    }

    return $self;
}

#-------------------------------------------------------------------------------

sub delete_property {
    my ($self, @prop_names) = @_;

    my $attrs = {key => 'stack_name_unique'};

    for my $prop_name (@prop_names) {
          my $where = {name => $prop_name};
          my $prop = $self->find_related('stack_properties', $where, $attrs);
          $prop->delete if $prop;
    }

    return $self;
}

#-------------------------------------------------------------------------------

sub delete_properties {
    my ($self) = @_;

    my $props_rs = $self->search_related_rs('stack_properties');
    $props_rs->delete;

    return $self;
}

#-------------------------------------------------------------------------------

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

#-------------------------------------------------------------------------------

sub default_format {
    my ($self) = @_;

    return '%k';
}

#-------------------------------------------------------------------------------
1;

__END__



# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
