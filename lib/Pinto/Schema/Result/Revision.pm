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

  data_type: 'boolean'
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

=head2 sha256

  data_type: 'text'
  default_value: (empty string)
  is_nullable: 1

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
  { data_type => "boolean", is_nullable => 0 },
  "committed_on",
  { data_type => "integer", is_nullable => 0 },
  "committed_by",
  { data_type => "text", is_nullable => 0 },
  "message",
  { data_type => "text", is_nullable => 0 },
  "sha256",
  { data_type => "text", default_value => "", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<stack_number_unique>

=over 4

=item * L</stack>

=item * L</number>

=back

=cut

__PACKAGE__->add_unique_constraint("stack_number_unique", ["stack", "number"]);

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

=head2 registration_changes

Type: has_many

Related object: L<Pinto::Schema::Result::RegistrationChange>

=cut

__PACKAGE__->has_many(
  "registration_changes",
  "Pinto::Schema::Result::RegistrationChange",
  { "foreign.revision" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
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
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "NO ACTION",
  },
);

=head1 L<Moose> ROLES APPLIED

=over 4

=item * L<Pinto::Role::Schema::Result>

=back

=cut


with 'Pinto::Role::Schema::Result';


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2012-11-12 10:50:21
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:o2TjxJl1rLE6Uae0Eic6Lg

#------------------------------------------------------------------------------

# ABSTRACT: A group of changes to a stack

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

use Pinto::Exception qw(throw);

use DateTime;
use String::Format;
use Digest::SHA;

use Pinto::Util qw(itis);

use overload ( '""'  => 'to_string',
               '<=>' => 'compare',
               'cmp' => 'compare' );

#------------------------------------------------------------------------------

__PACKAGE__->inflate_column('committed_on' => {
   inflate => sub { DateTime->from_epoch(epoch => $_[0]) }
});

#------------------------------------------------------------------------------

sub FOREIGNBUILDARGS {
  my ($class, $args) = @_;

  # TODO: Should we really default these here or in the DB?

  $args ||= {};
  $args->{message}      ||= '';
  $args->{committed_by} ||= '';
  $args->{committed_on}   = 0;
  $args->{is_committed}   = 0;

  return $args;
}

#------------------------------------------------------------------------------

sub insert {
    my ($self) = @_;

    my $new_revnum = $self->new_revision_number;
    $self->number($new_revnum);

    return $self->next::method;
}

#------------------------------------------------------------------------------

sub new_revision_number {
    my ($self) = @_;

    my $stack = $self->stack;

    # If we don't have a stack attribute, it probably means that it
    # doesn't exist yet and we are about to create it in this revision.
    return 0 if not $stack;

    my $where = { stack => $self->stack->id };
    my $revision_rs = $self->result_source->resultset->search($where);

    # Revision numbers are zero-based.  So just counting the number
    # of revisions will give us the number for the next one.
    return $revision_rs->count;
}

#------------------------------------------------------------------------------

sub previous_revision {
    my ($self) = @_;

    my $attrs = { key => 'stack_number_unique' };
    my $where = { stack => $self->stack, number => ($self->number - 1) };
    my $previous_revision = $self->result_source->resultset->find($where, $attrs);

    return defined $previous_revision ? $previous_revision : ();
}

#------------------------------------------------------------------------------

sub next_revision {
    my ($self) = @_;

    my $attrs = { key => 'stack_number_unique' };
    my $where = { stack => $self->stack, number => ($self->number + 1) };
    my $previous_revision = $self->result_source->resultset->find($where, $attrs);

    return defined $previous_revision ? $previous_revision : ();
}


#------------------------------------------------------------------------------

sub close {
    my ($self, %args) = @_;

    throw "Revision $self is already closed"
      if $self->is_committed;

    throw "Must specify a message to close revision $self"
       unless $args{message} or $self->message;

    throw "Must specify a username to close revision $self"
       unless $args{committed_by} or $self->committed_by;

    throw "Must specify a stack to close revision $self"
       unless $args{stack} or $self->stack;

    $self->update( { %args,
                     committed_on => time,
                     is_committed => 1,
                     sha256       => $self->compute_sha256 } );

    return $self;
}

#------------------------------------------------------------------------------

sub compute_sha256 {
    my ($self) = @_;

    throw "Must bind revision to a stack before computing checksum"
      if not $self->stack;

    my $attrs   = {select => [qw(package_name package_version distribution_path)] };
    my $rs      = $self->stack->search_related_rs('registrations', {}, $attrs);

    my $sha = Digest::SHA->new(256);
    $sha->add( join '/', @{$_} ) for $rs->cursor->all;

    return $sha->hexdigest;
}

#------------------------------------------------------------------------------

sub undo {
    my ($self) = @_;

    $self->info("Undoing revision $self");

    $_->undo(stack => $self->stack) for reverse $self->registration_changes;

    return $self;
}

#------------------------------------------------------------------------------

sub change_details {
    my ($self) = @_;

    return join "\n", $self->registration_changes;
}

#------------------------------------------------------------------------------

sub message_title {
    my ($self, $max_chars) = @_;

    my $message = $self->message;
    my $title = (split /\n/, $message)[0];

    if ($max_chars) {
      $title = substr($title, 0, $max_chars - 3,) . '...';
    }

    return $title;
}

#------------------------------------------------------------------------------

sub message_body {
    my ($self) = @_;

    my $message = $self->message;
    my $body = ($message =~ m/^ [^\n]+ \n+ (.*)/xms) ? $1 : '';

    return $body;
}

#------------------------------------------------------------------------------

sub compare {
    my ($rev_a, $rev_b) = @_;

    my $pkg = __PACKAGE__;
    throw "Can only compare $pkg objects"
        if not ( itis($rev_a, $pkg) && itis($rev_b, $pkg) );

    return 0 if $rev_a->id == $rev_b->id;

    my $r = ($rev_a->committed_on <=> $rev_b->committed_on);

    return $r;
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
           u => sub { $self->committed_on->strftime('%c') . ' UTC'         },

    );

    $format ||= $self->default_format;
    return String::Format::stringf($format, %fspec);
}

#-------------------------------------------------------------------------------

sub default_format {
    my ($self) = @_;

    return '%k@%b';
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------
1;

