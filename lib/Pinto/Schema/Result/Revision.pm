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
  default_value: null
  is_foreign_key: 1
  is_nullable: 1

=head2 number

  data_type: 'integer'
  is_nullable: 0

=head2 is_committed

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
  {
    data_type      => "integer",
    default_value  => \"null",
    is_foreign_key => 1,
    is_nullable    => 1,
  },
  "number",
  { data_type => "integer", is_nullable => 0 },
  "is_committed",
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

=head2 active_stack

Type: might_have

Related object: L<Pinto::Schema::Result::Stack>

=cut

__PACKAGE__->might_have(
  "active_stack",
  "Pinto::Schema::Result::Stack",
  { "foreign.head_revision" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 registration_histories

Type: has_many

Related object: L<Pinto::Schema::Result::RegistrationHistory>

=cut

__PACKAGE__->has_many(
  "registration_histories",
  "Pinto::Schema::Result::RegistrationHistory",
  { "foreign.revision" => "self.id" },
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
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

=head1 L<Moose> ROLES APPLIED

=over 4

=item * L<Pinto::Role::Schema::Result>

=back

=cut


with 'Pinto::Role::Schema::Result';


# Created by DBIx::Class::Schema::Loader v0.07025 @ 2012-09-13 11:16:34
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:gM9NKJV2APk6q78eSwufVQ

#------------------------------------------------------------------------------

# ABSTRACT: A group of changes to a stack

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

use Pinto::Exception qw(throw);

use String::Format;

use overload ( '""'  => 'to_string' );

#------------------------------------------------------------------------------

sub FOREIGNBUILDARGS {
  my ($class, $args) = @_;

  $args ||= {};
  $args->{committed_by} ||= $ENV{USER};
  $args->{committed_on} = 0;
  $args->{is_committed} = 0;
  $args->{number}       = -1;

  return $args;
}

#------------------------------------------------------------------------------

sub next_revision_number {
    my ($self) = @_;

    my $stack = $self->stack;
    return 0 if not $stack;

    my $where = { stack => $self->stack->id };
    my $revision_rs = $self->result_source->resultset->search($where);
    my $current_revision_number = $revision_rs->count;

    return $current_revision_number + 1;
}

#------------------------------------------------------------------------------

sub close {
    my ($self, %args) = @_;

    throw "Revision $self is already committed" if $self->is_committed;

    my $next = $self->next_revision_number;
    $self->update({%args, number => $next, committed_on => time, is_committed => 1});

    return $self;
}

#------------------------------------------------------------------------------

sub to_string {
    my ($self, $format) = @_;

    my %fspec = (

           # NOTE: It is possible to define a Revision without a
           # Stack.  This should only happen when creating a new
           # Stack.  There is a circular reference between Stacks and
           # Revisions, so one of them must come first.  Therefore, we
           # must be prepared for $self->stack to be undefined below.
           k => sub { defined $self->stack ? $self->stack->name : '()'    },

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

