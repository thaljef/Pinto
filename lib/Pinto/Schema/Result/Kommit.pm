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

=head2 digest

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
  "digest",
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


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-02-21 23:16:38
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:mltNkn+8FQYp/U4vxuM7aw

#------------------------------------------------------------------------------

# ABSTRACT: FIX ME!

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

use Pinto::Exception qw(throw);

use DateTime;
use DateTime::TimeZone;
use String::Format;
use Digest::SHA;

use Pinto::Exception qw(throw);
use Pinto::Util qw(itis trim current_time);

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

sub FOREIGNBUILDARGS {
  my ($class, $args) = @_;

  $args ||= {};
  $args->{sha256}       ||= '';
  $args->{message}      ||= '';
  $args->{username}     ||= '';
  $args->{timestamp}    ||=  0;

  return $args;
}

#------------------------------------------------------------------------------

sub insert {
  my ($self) = @_;

  $self->next::method;

  $self->create_related(kommit_graph_ancestors => { descendant => $self, 
                                                    depth      => 0 });

  return $self;
}

#------------------------------------------------------------------------------

sub finalize {
    my ($self, %args) = @_;

    if (not $self->message) {
      throw "Cannot finalize kommit $self without a message" unless $args{message};
      $self->message( $args{message} );
    }

    if (not $self->username) {
      throw "Cannot finalize kommit $self without a username" unless $args{username};
      $self->username( $args{username} );
    }

    $self->timestamp( current_time );
    $self->sha256( $self->compute_digest );

    return $self->update;

}
#------------------------------------------------------------------------------

sub message_title {
    my ($self, $max_chars) = @_;

    my $message = $self->message;
    my $title = trim( (split /\n/, $message)[0] );

    if ($max_chars and length $title > $max_chars) {
      $title = substr($title, 0, $max_chars - 3,) . '...';
    }

    return $title;
}

#------------------------------------------------------------------------------

sub message_body {
    my ($self) = @_;

    my $message = $self->message;
    my $body = ($message =~ m/^ [^\n]+ \n+ (.*)/xms) ? $1 : '';

    return trim($body);
}

#------------------------------------------------------------------------------

sub sha256_short {
    my ($self) = @_;

    return substr $self->sha256, 0, 8;
}

#------------------------------------------------------------------------------

sub compute_digest {
    my ($self) = @_;

    my $string = join '|', $self->registrations->get_column('package'),
                           $self->timestamp->hires_epoch,
                           $self->username,
                           $self->message;

    my $sha = Digest::SHA->new(1);
    $sha->add($string);

    return $sha->hexdigest;
}

#------------------------------------------------------------------------------

sub add_parent {
    my ($self, $parent) = @_;

    my $child_id  = $self->id;
    my $parent_id = $parent->id;

    my $sql = "INSERT INTO kommit_graph (ancestor, descendant, depth) "
            . "SELECT ancestor, $child_id, depth + 1 FROM kommit_graph "
            . "WHERE descendant = $parent_id ";

    my $dbh = $self->result_source->schema->storage->dbh;
    $dbh->do($sql);

    return;
}

#------------------------------------------------------------------------------

sub ancestors {
  my ($self) = @_;

  my $where = {descendant =>  $self->id, ancestor => {'!=' => $self->id}};
  my $attrs = {join => 'kommit_graph_ancestors', order_by => {-desc => 'me.timestamp'}, distinct => 1};

  return $self->result_source->resultset->search($where, $attrs);
}

#------------------------------------------------------------------------------

sub is_ancestor_to {
  my ($self, $kommit) = @_;

  my $where = {descendant =>  $kommit->id, ancestor => $self->id};
  my $attrs = {join => 'kommit_graph_ancestors'};

  return $self->result_source->resultset->search($where, $attrs)->count;
}

#------------------------------------------------------------------------------

sub descendants {
  my ($self) = @_;

  my $where = {ancestor =>  $self->id, descendant => {'!=' => $self->id}};
  my $attrs = {join => 'kommit_graph_descendants', order_by => 'me.timestamp', distinct => 1};

  return $self->result_source->resultset->search($where, $attrs);
}

#------------------------------------------------------------------------------

sub is_descendant_of {
  my ($self, $kommit) = @_;

  my $where = {descendant =>  $self->id, ancestor => $kommit->id};
  my $attrs = {join => 'kommit_graph_descendants'};

  return $self->result_source->resultset->search($where, $attrs)->count;
}

#------------------------------------------------------------------------------

sub parents {
  my ($self) = @_;

  my $where = {descendant => $self->id, ancestor => {'!=' => $self->id}, depth => 1};
  my $attrs = {join => 'kommit_graph_ancestors', order_by => 'me.timestamp'};

  return $self->result_source->resultset->search($where, $attrs);
}

#------------------------------------------------------------------------------

sub children {
  my ($self) = @_;

  my $where = {ancestor => $self->id, descendant => {'!=' => $self->id}, depth => 1};
  my $attrs = {join => 'kommit_graph_descendants', order_by => 'me.timestamp'};

  return $self->result_source->resultset->search($where, $attrs);
}

#------------------------------------------------------------------------------

sub is_root_kommit {
  my ($self) = @_;

  # TODO: use the root's digest to test for identity
  return $self->id == 1;
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

           i => sub { $self->sha256_short              },
           I => sub { $self->sha256                    },
           g => sub { $self->message                   },
           j => sub { $self->username                  },
           u => sub { $self->timestamp->strftime('%c') },

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
