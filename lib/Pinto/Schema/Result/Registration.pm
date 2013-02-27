use utf8;
package Pinto::Schema::Result::Registration;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Pinto::Schema::Result::Registration

=cut

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

=head1 TABLE: C<registration>

=cut

__PACKAGE__->table("registration");

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

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "stack",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "package",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "package_name",
  { data_type => "text", is_nullable => 0 },
  "distribution",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "is_pinned",
  { data_type => "boolean", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<stack_package_name_unique>

=over 4

=item * L</stack>

=item * L</package_name>

=back

=cut

__PACKAGE__->add_unique_constraint("stack_package_name_unique", ["stack", "package_name"]);

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


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-02-21 23:16:38
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:zPM+eyNERxwrZe7WfmQ5cg

#------------------------------------------------------------------------------

# ABSTRACT: Represents the relationship between a Package and a Stack

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

use Carp;
use String::Format;

use Pinto::Util qw(itis);
use Pinto::Exception qw(throw);

use overload ( '""'     => 'to_string',
               'cmp'    => 'string_compare',
               '<=>'    => 'numeric_compare',
               fallback => undef );

#-------------------------------------------------------------------------------

sub FOREIGNBUILDARGS {
    my ($class, $args) = @_;

    # Should we default these here or in the database?

    $args ||= {};
    $args->{is_pinned} ||= 0;

    return $args;
}

#-------------------------------------------------------------------------------

# sub insert {
#     my ($self) = @_;

#     my $change = { event        => 'insert',
#                    revision     => 1,
#                    package      => $self->package->id,
#                    package_name => $self->package_name,
#                    distribution => $self->distribution->id,
#                    is_pinned    => $self->is_pinned };

#     #$self->result_source->schema->create_registration_change($change);

#     return $self->next::method;
# }

# #-------------------------------------------------------------------------------

# sub delete {
#     my ($self) = @_;

#     my $change = { event        => 'delete',
#                    revision     => 1,
#                    package_name => $self->package_name };

#     #$self->result_source->schema->create_registration_change($change);

#     return $self->next::method;
# }

#-------------------------------------------------------------------------------

sub pin {
    my ($self) = @_;

    throw "$self is already pinned" if $self->is_pinned;

    $self->delete;
    my $copy = $self->copy({is_pinned => 1});


    return $copy;
}

#-------------------------------------------------------------------------------

sub unpin {
    my ($self) = @_;

    throw "$self is not pinned" if not $self->is_pinned;

    $self->delete;
    my $copy = $self->copy({is_pinned => 0});


    return $copy;
}

#-------------------------------------------------------------------------------

sub numeric_compare {
    my ($reg_a, $reg_b) = @_;

    my $pkg = __PACKAGE__;
    throw "Can only compare $pkg objects"
        if not ( itis($reg_a, $pkg) && itis($reg_b, $pkg) );

    return 0 if $reg_a->id == $reg_b->id;

    return $reg_a->package <=> $reg_b->package;
};

#------------------------------------------------------------------------------

sub string_compare {
    my ($reg_a, $reg_b) = @_;

    my $class = __PACKAGE__;
    throw "Can only compare $class objects"
        if not ( itis($reg_a, $class) && itis($reg_b, $class) );

    return 0 if $reg_a->id == $reg_b->id;

    return    ($reg_a->package->distribution->author cmp $reg_b->package->distribution->author)
           || ($reg_a->package->distribution->vname  cmp $reg_b->package->distribution->vname)
           || ($reg_a->package->vname                cmp $reg_b->package->vname);
}

#------------------------------------------------------------------------------

sub to_string {
    my ($self, $format) = @_;

    # my ($pkg, $file, $line) = caller;
    # warn __PACKAGE__ . " stringified from $file at line $line";

    my %fspec = (
         p => sub { $self->package->name                                     },
         P => sub { $self->package->vname                                    },
         v => sub { $self->package->version                                  },
         y => sub { $self->is_pinned                        ? '*' : ' '      },
         m => sub { $self->package->distribution->is_devel  ? 'd' : 'r'      },
         h => sub { $self->package->distribution->path                       },
         H => sub { $self->package->distribution->native_path                },
         f => sub { $self->package->distribution->archive                    },
         s => sub { $self->package->distribution->is_local  ? 'l' : 'f'      },
         S => sub { $self->package->distribution->source                     },
         a => sub { $self->package->distribution->author                     },
         d => sub { $self->package->distribution->name                       },
         D => sub { $self->package->distribution->vname                      },
         V => sub { $self->package->distribution->version                    },
         u => sub { $self->package->distribution->url                        },
         k => sub { $self->stack->name                                       },
    );

    # Some attributes are just undefined, usually because of
    # oddly named distributions and other old stuff on CPAN.
    no warnings 'uninitialized';  ## no critic qw(NoWarnings);

    $format ||= $self->default_format();
    return String::Format::stringf($format, %fspec);
}


#-------------------------------------------------------------------------------

sub default_format {

    return '%a/%D/%P/%k'; # AUTHOR/DIST_VNAME/PKG_VNAME/STACK
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------
1;

__END__
