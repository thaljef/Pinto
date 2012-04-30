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

=head2 is_pinned

  data_type: 'integer'
  is_nullable: 0

=head2 package_name

  data_type: 'text'
  is_nullable: 0

=head2 package_version

  data_type: 'text'
  is_nullable: 0

=head2 distribution_path

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
  "package_name",
  { data_type => "text", is_nullable => 0 },
  "package_version",
  { data_type => "text", is_nullable => 0 },
  "distribution_path",
  { data_type => "text", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<stack_package_name_distribution_path_unique>

=over 4

=item * L</stack>

=item * L</package_name>

=item * L</distribution_path>

=back

=cut

__PACKAGE__->add_unique_constraint(
  "stack_package_name_distribution_path_unique",
  ["stack", "package_name", "distribution_path"],
);

=head2 C<stack_package_name_unique>

=over 4

=item * L</stack>

=item * L</package_name>

=back

=cut

__PACKAGE__->add_unique_constraint("stack_package_name_unique", ["stack", "package_name"]);

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


# Created by DBIx::Class::Schema::Loader v0.07015 @ 2012-04-30 16:51:35
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:GGTezlBFUghgmmhn8Uf20A

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

use Carp;
use String::Format;

use overload ( '""'     => 'to_string',
               '<=>'    => 'compare',
               fallback => undef );

#-------------------------------------------------------------------------------

sub FOREIGNBUILDARGS {
    my ($class, $args) = @_;

    $args ||= {};
    $args->{is_pinned} ||= 0;

    return $args;
}

#-------------------------------------------------------------------------------

sub insert {
    my ($self, @args) = @_;

    # Denormalize a bit..
    $self->package_name($self->package->name);
    $self->package_version($self->package->version->stringify);
    $self->distribution_path($self->package->distribution->path);

    $self->stack->touch;

    return $self->next::method(@args);
}

#-------------------------------------------------------------------------------

sub update {
    my ($self, @args) = @_;

    my $r = $self->next::method(@args);

    # HACK: This forces the name, version, and path fields to always come
    # from the related package/distribution objects.  So you cannot explictly
    # set these yourself.  There is probably a better way to do this.

    my $changes = {};
    $changes->{package_name}      = $self->package->name;
    $changes->{package_version}   = $self->package->version;
    $changes->{distribution_path} = $self->package->distribution->path;

    $self->stack->touch;

    return $self->next::method($changes);
}

#-------------------------------------------------------------------------------

sub delete {
    my ($self, @args) = @_;

    $self->stack->touch;

    return $self->next::method(@args);
}

#-------------------------------------------------------------------------------

sub pin {
    my ($self) = @_;
    return $self->update({is_pinned => 1});
}

#-------------------------------------------------------------------------------

sub unpin {
    my ($self) = @_;
    return $self->update({is_pinned => 0});
}

#-------------------------------------------------------------------------------

sub compare {
    my ($reg_a, $reg_b) = @_;

    my $pkg = __PACKAGE__;
    confess "Can only compare $pkg objects"
        if ($pkg ne ref $reg_a) || ($pkg ne ref $reg_b);

    return 0 if $reg_a->id == $reg_b->id;

    my $r =   ( $reg_a->is_pinned <=> $reg_b->is_pinned  )
           || ( $reg_a->package   <=> $reg_b->package    );

    return $r;
};

#------------------------------------------------------------------------------

sub to_string {
    my ($self, $format) = @_;

    my %fspec = (
         'n' => sub { $self->name                                            },
         'N' => sub { $self->package->vname                                  },
         'v' => sub { $self->version                                         },
         'm' => sub { $self->package->distribution->is_devel  ? 'd' : 'r'    },
         'p' => sub { $self->path                                            },
         'P' => sub { $self->package->distribution->archive                  },
         's' => sub { $self->package->distribution->is_local  ? 'l' : 'f'    },
         'S' => sub { $self->package->distribution->source                   },
         'a' => sub { $self->package->distribution->author                   },
         'd' => sub { $self->package->distribution->name                     },
         'D' => sub { $self->package->distribution->vname                    },
         'w' => sub { $self->package->distribution->version                  },
         'u' => sub { $self->package->distribution->url                      },
         'k' => sub { $self->stack->name                                     },
         'e' => sub { $self->stack->description                              },
         'u' => sub { $self->stack->mtime                                    },
         'U' => sub { scalar localtime $self->stack->mtime                   },
         'y' => sub { $self->is_pinned                        ? '+' : ' '    },
    );

    # Some attributes are just undefined, usually because of
    # oddly named distributions and other old stuff on CPAN.
    no warnings 'uninitialized';  ## no critic qw(NoWarnings);

    $format ||= $self->default_format();
    return String::Format::stringf($format, %fspec);
}


#-------------------------------------------------------------------------------

sub default_format {

    return '%a/%D/%N/%k';
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------
1;

__END__
