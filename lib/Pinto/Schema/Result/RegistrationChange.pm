use utf8;
package Pinto::Schema::Result::RegistrationChange;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Pinto::Schema::Result::RegistrationChange

=cut

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

=head1 TABLE: C<registration_change>

=cut

__PACKAGE__->table("registration_change");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 event

  data_type: 'text'
  is_nullable: 0

=head2 package

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 package_name

  data_type: 'text'
  is_nullable: 0

=head2 distribution

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 is_pinned

  data_type: 'boolean'
  is_nullable: 0

=head2 kommit

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "event",
  { data_type => "text", is_nullable => 0 },
  "package",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "package_name",
  { data_type => "text", is_nullable => 0 },
  "distribution",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "is_pinned",
  { data_type => "boolean", is_nullable => 0 },
  "kommit",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<event_package_name_kommit_unique>

=over 4

=item * L</event>

=item * L</package_name>

=item * L</kommit>

=back

=cut

__PACKAGE__->add_unique_constraint(
  "event_package_name_kommit_unique",
  ["event", "package_name", "kommit"],
);

=head1 RELATIONS

=head2 distribution

Type: belongs_to

Related object: L<Pinto::Schema::Result::Distribution>

=cut

__PACKAGE__->belongs_to(
  "distribution",
  "Pinto::Schema::Result::Distribution",
  { id => "distribution" },
  { is_deferrable => 0, on_delete => "CASCADE", on_update => "NO ACTION" },
);

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

=head2 package

Type: belongs_to

Related object: L<Pinto::Schema::Result::Package>

=cut

__PACKAGE__->belongs_to(
  "package",
  "Pinto::Schema::Result::Package",
  { id => "package" },
  { is_deferrable => 0, on_delete => "CASCADE", on_update => "NO ACTION" },
);

=head1 L<Moose> ROLES APPLIED

=over 4

=item * L<Pinto::Role::Schema::Result>

=back

=cut


with 'Pinto::Role::Schema::Result';


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2012-12-01 23:52:04
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:rW0oK29FSyYHZ4HPIeFSmw

#-------------------------------------------------------------------------------

# ABSTRACT: A single change to the registry

#-------------------------------------------------------------------------------

# VERSION

#-------------------------------------------------------------------------------

use String::Format;

use Pinto::Exception qw(throw);

use overload ( q{""} => 'to_string' );

#-------------------------------------------------------------------------------

sub undo {
    my ($self, %args) = @_;

    my $stack = $args{stack};

    my $state = { stack        => $stack,
                  package      => $self->package,
                  package_name => $self->package_name,
                  distribution => $self->distribution,
                  is_pinned    => $self->is_pinned };

    my $event = $self->event;
    if ($event eq 'insert') {

        my $attrs = { key => 'stack_package_unique' };
        my $reg = $self->result_source->schema->resultset('Registration')->find($state, $attrs);
        throw "Found no registrations matching $self on stack $stack" if not defined $reg;

        $reg->delete;
        $self->debug( sub {"Deleted $self"} );

    }
    elsif ($event eq 'delete') {

        $self->result_source->schema->resultset('Registration')->create($state);
        $self->debug( sub {"Restored $self"} );

    }
    else {
      throw "Don't know how to undo event $event";
    }

    return $self;

}

#-------------------------------------------------------------------------------

sub to_string {
   my ($self, $format) = @_;


    my %fspec = (
         A => sub { $self->event eq 'insert'                    ? 'A' : 'D'         },
         n => sub { $self->package->name                                            },
         N => sub { $self->package->vname                                           },
         v => sub { $self->package->version                                         },
         m => sub { $self->package->distribution->is_devel      ? 'd' : 'r'         },
         p => sub { $self->package->distribution->path                              },
         P => sub { $self->package->distribution->native_path                       },
         f => sub { $self->package->distribution->archive                           },
         s => sub { $self->package->distribution->is_local      ? 'l' : 'f'         },
         S => sub { $self->package->distribution->source                            },
         a => sub { $self->package->distribution->author                            },
         d => sub { $self->package->distribution->name                              },
         D => sub { $self->package->distribution->vname                             },
         w => sub { $self->package->distribution->version                           },
         u => sub { $self->package->distribution->url                               },
         j => sub { $self->kommit->committed_by                                     },
         u => sub { $self->kommit->committed_on->strftime('%c')                     },
         y => sub { $self->is_pinned                            ? '+' : ' '         },
    );

    # Some attributes are just undefined, usually because of
    # oddly named distributions and other old stuff on CPAN.
    no warnings 'uninitialized';  ## no critic qw(NoWarnings);

    $format ||= $self->default_format();
    return String::Format::stringf($format, %fspec);
}

sub default_format {

    return '%A %y %a/%f/%N';
}

#-------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#-------------------------------------------------------------------------------
1;

__END__

