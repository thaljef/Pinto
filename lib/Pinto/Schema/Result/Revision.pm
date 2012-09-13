use utf8;
package Pinto::Schema::Result::Revision;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Pinto::Schema::Result::Revision

=cut

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

=head1 TABLE: C<revision>

=cut

__PACKAGE__->table("revision");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 stack

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 number

  data_type: 'integer'
  is_nullable: 0

=head2 committed_on

  data_type: 'integer'
  is_nullable: 0

=head2 committed_by

  data_type: 'text'
  is_nullable: 0

=head2 message

  data_type: 'text'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "stack",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "number",
  { data_type => "integer", is_nullable => 0 },
  "committed_on",
  { data_type => "integer", is_nullable => 0 },
  "committed_by",
  { data_type => "text", is_nullable => 0 },
  "message",
  { data_type => "text", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 registration_histories_created_in_revision

Type: has_many

Related object: L<Pinto::Schema::Result::RegistrationHistory>

=cut

__PACKAGE__->has_many(
  "registration_histories_created_in_revision",
  "Pinto::Schema::Result::RegistrationHistory",
  { "foreign.created_in_revision" => "self.id" },
  { cascade_copy => 0, cascade_delete => 1 },
);

=head2 registration_histories_deleted_in_revision

Type: has_many

Related object: L<Pinto::Schema::Result::RegistrationHistory>

=cut

__PACKAGE__->has_many(
  "registration_histories_deleted_in_revision",
  "Pinto::Schema::Result::RegistrationHistory",
  { "foreign.deleted_in_revision" => "self.id" },
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

=head2 stacks

Type: has_many

Related object: L<Pinto::Schema::Result::Stack>

=cut

__PACKAGE__->has_many(
  "stacks",
  "Pinto::Schema::Result::Stack",
  { "foreign.head_revision" => "self.id" },
  { cascade_copy => 0, cascade_delete => 1 },
);

=head1 L<Moose> ROLES APPLIED

=over 4

=item * L<Pinto::Role::Schema::Result>

=back

=cut


with 'Pinto::Role::Schema::Result';


# Created by DBIx::Class::Schema::Loader v0.07025 @ 2012-09-12 13:44:20
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:OT6AaEWHhXSGwBqH0WH1bQ

#------------------------------------------------------------------------------

# ABSTRACT: A group of changes to a stack

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

use String::Format;

use overload ( '""'  => 'to_string' );

#------------------------------------------------------------------------------

sub FOREIGNBUILDARGS {
  my ($class, $args) = @_;

  $args ||= {};
  $args->{committed_on} ||= time;
  $args->{committed_by} ||= $ENV{USER};

  delete $args->{guard}; # Not part of the table

  return $args;
}

#------------------------------------------------------------------------------

has guard => (
    is       => 'ro',
    isa      => 'DBIx::Class::Storage::TxnScopeGuard',
    handles  => [ qw( commit rollback ) ],
    required => 1,
);

#------------------------------------------------------------------------------

sub insert {
    my ($self) = @_;

    $self->number( $self->next_revision_number );

    return $self->next::method;
}

#------------------------------------------------------------------------------

sub next_revision_number {
    my ($self) = @_;

    my $where = { stack => $self->stack->id };
    my $revision_rs = $self->result_source->resultset->search($where);
    my $revision_number_rs = $revision_rs->get_column('number');
    my $current_revision_number = $revision_number_rs->max;

    return defined $current_revision_number ? $current_revision_number + 1 : 0;
}

#------------------------------------------------------------------------------

sub to_string {
    my ($self, $format) = @_;

    my %fspec = (
           k => sub { $self->stack->name                                   },
           b => sub { $self->number                                        },
           g => sub { $self->message                                       },
           j => sub { $self->committed_by                                  },
           u => sub { $self->committed_on                                  },

    );

    $format ||= $self->default_format;
    return String::Format::stringf($format, %fspec);
}

#-------------------------------------------------------------------------------

sub default_format {
    my ($self) = @_;

    return '%k: %02b %g';
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------
1;

