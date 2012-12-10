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

=head2 kommit

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 number

  data_type: 'integer'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "stack",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "kommit",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "number",
  { data_type => "integer", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<stack_kommit_unique>

=over 4

=item * L</stack>

=item * L</kommit>

=back

=cut

__PACKAGE__->add_unique_constraint("stack_kommit_unique", ["stack", "kommit"]);

=head2 C<stack_number_unique>

=over 4

=item * L</stack>

=item * L</number>

=back

=cut

__PACKAGE__->add_unique_constraint("stack_number_unique", ["stack", "number"]);

=head1 RELATIONS

=head2 kommit

Type: belongs_to

Related object: L<Pinto::Schema::Result::Kommit>

=cut

__PACKAGE__->belongs_to(
  "kommit",
  "Pinto::Schema::Result::Kommit",
  { id => "kommit" },
  { is_deferrable => 0, on_delete => "CASCADE", on_update => "NO ACTION" },
);

=head2 stack

Type: belongs_to

Related object: L<Pinto::Schema::Result::Stack>

=cut

__PACKAGE__->belongs_to(
  "stack",
  "Pinto::Schema::Result::Stack",
  { id => "stack" },
  { is_deferrable => 0, on_delete => "CASCADE", on_update => "NO ACTION" },
);

=head1 L<Moose> ROLES APPLIED

=over 4

=item * L<Pinto::Role::Schema::Result>

=back

=cut


with 'Pinto::Role::Schema::Result';


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2012-12-01 01:49:12
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:N/Zrnn9ec46OmMTcTLJOWA

#------------------------------------------------------------------------------

# ABSTRACT: A group of changes to a stack

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

use Pinto::Exception qw(throw);

use DateTime;
use String::Format;
use Digest::SHA;

use Pinto::Util qw(itis trim);

use overload ( '""'  => 'to_string',
               '<=>' => 'compare' );

#------------------------------------------------------------------------------

sub insert {
    my ($self) = @_;

    unless (defined $self->number) {
      my $new_revnum = $self->new_revision_number;
      $self->number($new_revnum);
    }
    
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

    # Revision numbers are zero-based.  So just counting the number of
    # revisions should give us the next revision number.
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
      if $self->kommit->is_committed;

    throw "Must specify a message to close revision $self"
       unless $args{message} or $self->message;

    throw "Must specify a username to close revision $self"
       unless $args{username} or $self->kommit->username;

    throw "Must specify a stack to close revision $self"
       unless $args{stack} or $self->stack;

    $self->kommit->update( {%args,
                            timestamp => time,
                            is_committed => 1} );

    return $self;
}

#------------------------------------------------------------------------------

sub undo {
    my ($self) = @_;

    $self->info("Undoing revision $self");

    my $attrs = { prefetch => [qw(package distribution)],
                  order_by => { -desc => 'me.id'} };

    my @changes = $self->kommit->registration_changes(undef, $attrs);

    $_->undo(stack => $self->stack) for @changes;

    return $self;
}

#------------------------------------------------------------------------------

sub compare {
    my ($rev_a, $rev_b) = @_;

    my $pkg = __PACKAGE__;
    throw "Can only compare $pkg objects"
        if not ( itis($rev_a, $pkg) && itis($rev_b, $pkg) );

    return 0 if $rev_a->id == $rev_b->id;

    my $r = ($rev_a->timestamp <=> $rev_b->timestamp);

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
           k => sub { defined $self->stack ? $self->stack->name : '()'   },

           b => sub { $self->number                                      },
           g => sub { $self->kommit->message                             },
           j => sub { $self->kommit->username                        },
           u => sub { $self->kommit->timestamp->strftime('%c')        },

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

