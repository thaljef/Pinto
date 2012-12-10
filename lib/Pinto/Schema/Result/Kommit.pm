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

=head2 is_committed

  data_type: 'boolean'
  is_nullable: 0

=head2 timestamp

  data_type: 'integer'
  is_nullable: 0

=head2 username

  data_type: 'text'
  is_nullable: 0

=head2 message

  data_type: 'text'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "is_committed",
  { data_type => "boolean", is_nullable => 0 },
  "timestamp",
  { data_type => "integer", is_nullable => 0 },
  "username",
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

=head2 revisions

Type: has_many

Related object: L<Pinto::Schema::Result::Revision>

=cut

__PACKAGE__->has_many(
  "revisions",
  "Pinto::Schema::Result::Revision",
  { "foreign.kommit" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head1 L<Moose> ROLES APPLIED

=over 4

=item * L<Pinto::Role::Schema::Result>

=back

=cut


with 'Pinto::Role::Schema::Result';


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2012-11-28 20:04:40
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:YFUWvngH4WbyGcUpZ3e3JA

#------------------------------------------------------------------------------

# ABSTRACT: FIX ME!

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

use Pinto::Exception qw(throw);

use DateTime;
use String::Format;

use Pinto::Util qw(itis trim);

use overload ( '""'  => 'to_string',
               '<=>' => 'compare' );

#------------------------------------------------------------------------------

__PACKAGE__->inflate_column('timestamp' => {
   inflate => sub { DateTime->from_epoch(epoch => $_[0]) }
});

#------------------------------------------------------------------------------

sub FOREIGNBUILDARGS {
  my ($class, $args) = @_;

  # TODO: Should we really default these here or in the DB?

  $args ||= {};
  $args->{message}      ||= '';
  $args->{username} ||= '';
  $args->{timestamp}   = 0;
  $args->{is_committed}   = 0;

  return $args;
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

sub compare {
    my ($kommit_a, $kommit_b) = @_;

    my $pkg = __PACKAGE__;
    throw "Can only compare $pkg objects"
        if not ( itis($kommit_a, $pkg) && itis($kommit_b, $pkg) );

    return 0 if $kommit_a->id == $kommit_b->id;

    my $r = ($kommit_a->timestamp <=> $kommit_b->timestamp);

    return $r;
}
#------------------------------------------------------------------------------

sub to_string {
    my ($self, $format) = @_;

    my %fspec = (

           g => sub { $self->message                      },
           j => sub { $self->username                 },
           u => sub { $self->timestamp->strftime('%c') },

    );

    $format ||= $self->default_format;
    return String::Format::stringf($format, %fspec);
}

#-------------------------------------------------------------------------------

sub default_format {
    my ($self) = @_;

    return '%g';
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------
1;
