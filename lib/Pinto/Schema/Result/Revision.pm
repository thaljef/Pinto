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

=head2 uuid

  data_type: 'text'
  is_nullable: 0

=head2 message

  data_type: 'text'
  is_nullable: 0

=head2 username

  data_type: 'text'
  is_nullable: 0

=head2 utc_time

  data_type: 'integer'
  is_nullable: 0

=head2 time_offset

  data_type: 'integer'
  is_nullable: 0

=head2 is_committed

  data_type: 'boolean'
  is_nullable: 0

=head2 has_changes

  data_type: 'boolean'
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
  "utc_time",
  { data_type => "integer", is_nullable => 0 },
  "time_offset",
  { data_type => "integer", is_nullable => 0 },
  "is_committed",
  { data_type => "boolean", is_nullable => 0 },
  "has_changes",
  { data_type => "boolean", is_nullable => 0 },
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

=head2 ancestry_children

Type: has_many

Related object: L<Pinto::Schema::Result::Ancestry>

=cut

__PACKAGE__->has_many(
  "ancestry_children",
  "Pinto::Schema::Result::Ancestry",
  { "foreign.child" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 ancestry_parents

Type: has_many

Related object: L<Pinto::Schema::Result::Ancestry>

=cut

__PACKAGE__->has_many(
  "ancestry_parents",
  "Pinto::Schema::Result::Ancestry",
  { "foreign.parent" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 registrations

Type: has_many

Related object: L<Pinto::Schema::Result::Registration>

=cut

__PACKAGE__->has_many(
  "registrations",
  "Pinto::Schema::Result::Registration",
  { "foreign.revision" => "self.id" },
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


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-03-07 12:56:52
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:u3EeZBioyg8H9+azCHQYNA

#------------------------------------------------------------------------------

# ABSTRACT: Represents a set of changes to a stack

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

use MooseX::Types::Moose qw(Str Bool);

use DateTime;
use DateTime::TimeZone;
use DateTime::TimeZone::OffsetOnly;
use String::Format;
use Digest::SHA;

use Pinto::Util qw(:all);

use overload ( '""'  => 'to_string',
               '<=>' => 'numeric_compare',
               'eq'  => 'equals' );

#------------------------------------------------------------------------------

# HACK: On perl-5.14.x (and possibly others) Package::Stash::XS has some funky
# behavior that causes Class::Load to think that certain modules are already 
# loaded when they actually are not.  This manifests in an error when
# DateTime::TimeZone tries to load DateTime::TimeZone::Local::Unix.  I don't
# know why it happens.  But loading it here explicitly prevents the problem.
# The module may or may not actually be used depending on your platform, and
# and forcibly loading it anway seems to be innocuous.  We use Class::Load
# quite a lot in Pinto, so this same bug may manifest in other places too.  For 
# the moment, this is the only one that I'm aware of.

use DateTime::TimeZone::Local::Unix;

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
  default     => sub { trim_text( title_text($_[0]->message) ) },
  init_arg    => undef,
  lazy        => 1,
);


has message_body => (
  is          => 'ro',
  isa         => Str,
  default     => sub { trim_text( body_text($_[0]->message) ) },
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


has datetime => (
  is         => 'ro',
  isa        => 'DateTime',
  default    => sub { DateTime->from_epoch(epoch => $_[0]->utc_time, time_zone => $_[0]->timezone) },
  init_arg   => undef,
  lazy       => 1,
);


has timezone => (
  is         => 'ro',
  isa        => 'DateTime::TimeZone',
  default    => sub { my $offset = DateTime::TimeZone->offset_as_string($_[0]->repo->config->time_offset);
                      return DateTime::TimeZone::OffsetOnly->new(offset => $offset) },
  init_arg   => undef,
  lazy       => 1,
);

#------------------------------------------------------------------------------

sub FOREIGNBUILDARGS {
  my ($class, $args) = @_;

  $args ||= {};
  $args->{uuid}         ||= uuid;
  $args->{username}     ||= '';
  $args->{utc_time}     ||= 0;
  $args->{time_offset}  ||= 0;
  $args->{is_committed} ||= 0;
  $args->{has_changes}  ||= 0;
  $args->{message}      ||= '';

  return $args;
}

#------------------------------------------------------------------------------

sub add_parent {
    my ($self, $parent) = @_;

    # TODO: Figure out how to do merges
    $self->create_related(ancestry_children => {parent => $parent->id});

    return;
}

#------------------------------------------------------------------------------

sub add_child {
    my ($self, $child) = @_;

    # TODO: Figure out how to do merges
    $self->create_related(ancestry_parents => {child => $child->id});

    return;
}

#------------------------------------------------------------------------------

sub parents {
  my ($self) = @_;

  my $where = {child => $self->id};
  my $attrs = {join => 'ancestry_parents', order_by => 'me.utc_time'};

  return $self->result_source->resultset->search($where, $attrs)->all;
}

#------------------------------------------------------------------------------

sub children {
  my ($self) = @_;

  my $where = {parent => $self->id};
  my $attrs = {join => 'ancestry_children', order_by => 'me.utc_time'};

  return $self->result_source->resultset->search($where, $attrs)->all;
}

#------------------------------------------------------------------------------

sub commit {
    my ($self, %args) = @_;

    throw "Must specify a message to commit" if not $args{message};

    $args{is_committed}   = 1;
    $args{has_changes}    = 0;
    $args{username}     ||= $self->repo->config->username;
    $args{time_offset}  ||= $self->repo->config->time_offset;
    $args{utc_time}     ||= current_utc_time;

    $self->update(\%args);

    return $self;
}

#------------------------------------------------------------------------------

sub assert_is_open {
    my ($self) = @_;

    # TODO: mark column dirty rather than refresh whole object.
    throw "PANIC: Revision $self is already committed"
      if $self->refresh->get_column('is_committed');

    return $self;
}


#-------------------------------------------------------------------------------

sub assert_is_committed {
    my ($self) = @_;

    # TODO: mark column dirty rather than refresh whole object.
    throw "PANIC: Revision $self is still open"
      if not $self->refresh->get_column('is_committed');

    return $self;
}

#-------------------------------------------------------------------------------

sub assert_has_changed {
    my ($self) = @_;

    # TODO: mark column dirty rather than refresh whole object.
    throw "PANIC: Revision $self has not changed"
      if not $self->refresh->get_column('has_changes');

    return $self;
}

#------------------------------------------------------------------------------

sub diff {
  my ($self, $other) = @_;

    my $left  = $other || ($self->parents)[0];
    my $right = $self;

    require Pinto::Difference;
    return  Pinto::Difference->new(left => $left, right => $right);
}

#------------------------------------------------------------------------------

sub numeric_compare {
    my ($revision_a, $revision_b) = @_;

    my $pkg = __PACKAGE__;
    throw "Can only compare $pkg objects"
        if not ( itis($revision_a, $pkg) && itis($revision_b, $pkg) );

    return 0 if $revision_a->id == $revision_b->id;

    my $r = ($revision_a->utc_time <=> $revision_b->utc_time);

    return $r;
}

#------------------------------------------------------------------------------

sub equals {
    my ($revision_a, $revision_b) = @_;

    my $pkg = __PACKAGE__;
    throw "Can only compare $pkg objects"
        if not ( itis($revision_a, $pkg) && itis($revision_b, $pkg) );

    return $revision_a->id == $revision_b->id;
}

#------------------------------------------------------------------------------

sub to_string {
    my ($self, $format) = @_;

    my %fspec = (
           i => sub { $self->uuid_prefix                              },
           I => sub { $self->uuid                                     },
           j => sub { $self->username                                 },
           u => sub { $self->datetime->strftime($_[0] || '%c')        },
           g => sub { $self->message_body                             },
           G => sub { indent_text( trim_text($self->message), $_[0] ) },
           t => sub { $self->message_title                            },
           T => sub { truncate_text( $self->message_title, $_[0] )    },
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

__END__