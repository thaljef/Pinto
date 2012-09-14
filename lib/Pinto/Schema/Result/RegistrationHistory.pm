use utf8;
package Pinto::Schema::Result::RegistrationHistory;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Pinto::Schema::Result::RegistrationHistory

=cut

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

=head1 TABLE: C<registration_history>

=cut

__PACKAGE__->table("registration_history");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 stack

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 package

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 is_pinned

  data_type: 'integer'
  is_nullable: 0

=head2 revision

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 action

  data_type: 'text'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "stack",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "package",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "is_pinned",
  { data_type => "integer", is_nullable => 0 },
  "revision",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "action",
  { data_type => "text", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<stack_package_is_pinned_revision_action_unique>

=over 4

=item * L</stack>

=item * L</package>

=item * L</is_pinned>

=item * L</revision>

=item * L</action>

=back

=cut

__PACKAGE__->add_unique_constraint(
  "stack_package_is_pinned_revision_action_unique",
  ["stack", "package", "is_pinned", "revision", "action"],
);

=head1 RELATIONS

=head2 package

Type: belongs_to

Related object: L<Pinto::Schema::Result::Package>

=cut

__PACKAGE__->belongs_to(
  "package",
  "Pinto::Schema::Result::Package",
  { id => "package" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 revision

Type: belongs_to

Related object: L<Pinto::Schema::Result::Revision>

=cut

__PACKAGE__->belongs_to(
  "revision",
  "Pinto::Schema::Result::Revision",
  { id => "revision" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
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

=head1 L<Moose> ROLES APPLIED

=over 4

=item * L<Pinto::Role::Schema::Result>

=back

=cut


with 'Pinto::Role::Schema::Result';


# Created by DBIx::Class::Schema::Loader v0.07025 @ 2012-09-13 11:16:34
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:8p6rdIb9PyEo4/Q2PJR6Kg

#-------------------------------------------------------------------------------

# ABSTRACT A single change to the registry

#-------------------------------------------------------------------------------

# VERSION

#-------------------------------------------------------------------------------

use String::Format;

use Pinto::Exception qw(throw);

use overload ( q{""} => 'to_string' );

#-------------------------------------------------------------------------------

sub undo {
    my ($self) = @_;

    my $state = { stack     => $self->stack->id,
                  package   => $self->package->id,
                  is_pinned => $self->is_pinned };

    my $action = $self->action;
    if ($action eq 'insert') {

        my $attrs = {key => 'stack_package_unique'};
        my $reg = $self->result_source->schema->resultset('Registration')->find($state, $attrs);
        throw "Found no registrations matching $self" if not $reg;
        $self->debug("Removing $reg");
        $reg->delete;

    }
    elsif ($action eq 'delete') {

        my $reg = $self->result_source->schema->resultset('Registration')->create($state);
        $self->debug("Restored $reg");

    }
    else {
      throw "Don't know how to undo action $action";
    }

    return $self;

}

#-------------------------------------------------------------------------------

sub to_string {
   my ($self, $format) = @_;


    my %fspec = (
         A => sub { $self->action eq 'insert'               ? 'A' : 'D'         },
         n => sub { $self->package->name                                        },
         N => sub { $self->package->vname                                       },
         v => sub { $self->package->version                                     },
         m => sub { $self->package->distribution->is_devel  ? 'd' : 'r'         },
         p => sub { $self->package->distribution->path                          },
         P => sub { $self->package->distribution->native_path                   },
         f => sub { $self->package->distribution->archive                       },
         s => sub { $self->package->distribution->is_local  ? 'l' : 'f'         },
         S => sub { $self->package->distribution->source                        },
         a => sub { $self->package->distribution->author                        },
         d => sub { $self->package->distribution->name                          },
         D => sub { $self->package->distribution->vname                         },
         w => sub { $self->package->distribution->version                       },
         u => sub { $self->package->distribution->url                           },
         k => sub { $self->stack->name                                          },
         M => sub { $self->stack->is_default                 ? '*' : ' '        },
         e => sub { $self->stack->get_property('description')                   },
         j => sub { $self->stack->head_revision->committed_by                   },
         u => sub { $self->stack->head_revision->committed_on                   },
         y => sub { $self->is_pinned                        ? '+' : ' '         },
    );

    # Some attributes are just undefined, usually because of
    # oddly named distributions and other old stuff on CPAN.
    no warnings 'uninitialized';  ## no critic qw(NoWarnings);

    $format ||= $self->default_format();
    return String::Format::stringf($format, %fspec);
}

sub default_format {

    return '%A %y %a/%D/%N';
}

#-------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#-------------------------------------------------------------------------------
1;

__END__
