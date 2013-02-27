use utf8;
package Pinto::Schema::Result::Kommit;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Pinto::Schema::Result::Kommit

=cut

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

=head1 TABLE: C<kommit>

=cut

__PACKAGE__->table("kommit");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 uuid

  data_type: 'text'
  is_nullable: 0

=head2 message

  data_type: 'text'
  is_nullable: 0

=head2 username

  data_type: 'text'
  is_nullable: 0

=head2 timestamp

  data_type: 'integer'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "uuid",
  { data_type => "text", is_nullable => 0 },
  "message",
  { data_type => "text", is_nullable => 0 },
  "username",
  { data_type => "text", is_nullable => 0 },
  "timestamp",
  { data_type => "integer", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<uuid_unique>

=over 4

=item * L</uuid>

=back

=cut

__PACKAGE__->add_unique_constraint("uuid_unique", ["uuid"]);

=head1 RELATIONS

=head2 kommit_graph_children

Type: has_many

Related object: L<Pinto::Schema::Result::KommitGraph>

=cut

__PACKAGE__->has_many(
  "kommit_graph_children",
  "Pinto::Schema::Result::KommitGraph",
  { "foreign.child" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 kommit_graph_parents

Type: has_many

Related object: L<Pinto::Schema::Result::KommitGraph>

=cut

__PACKAGE__->has_many(
  "kommit_graph_parents",
  "Pinto::Schema::Result::KommitGraph",
  { "foreign.parent" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 registration_changes

Type: has_many

Related object: L<Pinto::Schema::Result::RegistrationChange>

=cut

__PACKAGE__->has_many(
  "registration_changes",
  "Pinto::Schema::Result::RegistrationChange",
  { "foreign.kommit" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 stacks

Type: has_many

Related object: L<Pinto::Schema::Result::Stack>

=cut

__PACKAGE__->has_many(
  "stacks",
  "Pinto::Schema::Result::Stack",
  { "foreign.head" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head1 L<Moose> ROLES APPLIED

=over 4

=item * L<Pinto::Role::Schema::Result>

=back

=cut


with 'Pinto::Role::Schema::Result';


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-02-27 14:05:41
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Vo5N8tP9uauwwliEMN/f4w

#------------------------------------------------------------------------------

# ABSTRACT: FIX ME!

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

use MooseX::Types::Moose qw(Str Bool);

use DateTime;
use DateTime::TimeZone;
use String::Format;
use Digest::SHA;

use Pinto::Exception qw(throw);
use Pinto::Util qw(:all);

use overload ( '""'  => 'to_string',
               '<=>' => 'numeric_compare',
               'eq'  => 'equals' );

#------------------------------------------------------------------------------

# TODO: Make this a Pinto::Global
my $tz = DateTime::TimeZone->new(name => 'local');

#------------------------------------------------------------------------------

__PACKAGE__->inflate_column('timestamp' => {
   inflate => sub { DateTime->from_epoch(epoch => $_[0], time_zone => $tz) }
});

#------------------------------------------------------------------------------

has uuid_prefix => (
  is          => 'ro',
  isa         => Str,
  default     => sub { substr($_[0]->uuid, 0, 8) },
  init_arg    => undef,
  lazy        => 1,
);


has message_title => (
  is          => 'ro',
  isa         => Str,
  default     => sub { trim( title_text($_[0]->message) ) },
  init_arg    => undef,
  lazy        => 1,
);


has message_body => (
  is          => 'ro',
  isa         => Str,
  default     => sub { trim( body_text($_[0]->message) ) },
  init_arg    => undef,
  lazy        => 1,
);


has is_root => (
  is          => 'ro',
  isa         => Bool,
  default     => sub { $_[0]->id == 1 },
  init_arg    => undef,
  lazy        => 1,
);

#------------------------------------------------------------------------------

sub FOREIGNBUILDARGS {
  my ($class, $args) = @_;

  $args ||= {};
  $args->{uuid}      ||= uuid;
  $args->{username}  ||= current_username;
  $args->{timestamp} ||= current_time;

  return $args;
}

#------------------------------------------------------------------------------

sub add_parent {
    my ($self, $parent) = @_;

    $self->create_related(kommit_graph_children => {parent => $parent->id});

    return;
}

#------------------------------------------------------------------------------

sub add_child {
    my ($self, $child) = @_;

    $self->create_related(kommit_graph_parents => {child => $child->id});

    return;
}

#------------------------------------------------------------------------------

sub parents {
  my ($self) = @_;

  my $where = {child => $self->id};
  my $attrs = {join => 'kommit_graph_parents', order_by => 'me.timestamp'};

  return $self->result_source->resultset->search($where, $attrs)->all;
}

#------------------------------------------------------------------------------

sub children {
  my ($self) = @_;

  my $where = {parent => $self->id};
  my $attrs = {join => 'kommit_graph_children', order_by => 'me.timestamp'};

  return $self->result_source->resultset->search($where, $attrs)->all;
}

#------------------------------------------------------------------------------

sub numeric_compare {
    my ($kommit_a, $kommit_b) = @_;

    my $pkg = __PACKAGE__;
    throw "Can only compare $pkg objects"
        if not ( itis($kommit_a, $pkg) && itis($kommit_b, $pkg) );

    return 0 if $kommit_a->id == $kommit_b->id;

    my $r = ($kommit_a->timestamp <=> $kommit_b->timestamp);

    return $r;
}

#------------------------------------------------------------------------------

sub equals {
    my ($kommit_a, $kommit_b) = @_;

    my $pkg = __PACKAGE__;
    throw "Can only compare $pkg objects"
        if not ( itis($kommit_a, $pkg) && itis($kommit_b, $pkg) );

    return $kommit_a->id == $kommit_b->id;
}

#------------------------------------------------------------------------------

sub to_string {
    my ($self, $format) = @_;

    my %fspec = (
           i => sub { $self->uuid_prefix               },
           I => sub { $self->uuid                      },
           j => sub { $self->username                  },
           u => sub { $self->timestamp->strftime('%c') },
           g => sub { $self->message_body              },
           t => sub { $self->message_title             },
           G => sub { indent( $self->message, $_[0] )  },
    );

    $format ||= $self->default_format;
    return String::Format::stringf($format, %fspec);
}

#-------------------------------------------------------------------------------

sub default_format {
    my ($self) = @_;

    return '%i';
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------
1;
