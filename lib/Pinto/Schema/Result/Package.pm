package Pinto::Schema::Result::Package;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Pinto::Schema::Result::Package

=cut

__PACKAGE__->table("package");

=head1 ACCESSORS

=head2 package_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 name

  data_type: 'text'
  is_nullable: 0

=head2 version

  data_type: 'text'
  is_nullable: 0

=head2 is_latest

  data_type: 'boolean'
  default_value: NULL
  is_nullable: 1

=head2 distribution

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "package_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "name",
  { data_type => "text", is_nullable => 0 },
  "version",
  { data_type => "text", is_nullable => 0 },
  "is_latest",
  { data_type => "boolean", default_value => \"NULL", is_nullable => 1 },
  "distribution",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);
__PACKAGE__->set_primary_key("package_id");
__PACKAGE__->add_unique_constraint("name_is_latest_unique", ["name", "is_latest"]);
__PACKAGE__->add_unique_constraint("name_distribution_unique", ["name", "distribution"]);

=head1 RELATIONS

=head2 distribution

Type: belongs_to

Related object: L<Pinto::Schema::Result::Distribution>

=cut

__PACKAGE__->belongs_to(
  "distribution",
  "Pinto::Schema::Result::Distribution",
  { distribution_id => "distribution" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-09-25 13:47:31
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ZgkSh8Qg5GKkwz+GFULT8A

#------------------------------------------------------------------------------

# ABSTRACT: Represents a package in a Distribution

#------------------------------------------------------------------------------

use String::Format;

use Pinto::Util;
use Pinto::Exceptions qw(throw_error);

use overload ( '""'     => 'to_string',
               '<=>'    => 'compare_version',
               fallback => undef );

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

sub new {
    my ($class, $attrs) = @_;

    $attrs->{version} = 'undef'
        if not defined $attrs->{version};

    return $class->SUPER::new($attrs);
}

#------------------------------------------------------------------------------

sub vname {
    my ($self) = @_;

    return $self->name() . '-' . $self->version();
}

#------------------------------------------------------------------------------

sub author {
    my ($self) = @_;

    return $self->distribution->author();
}

#------------------------------------------------------------------------------

sub is_local {
    my ($self) = @_;

    return $self->distribution->is_local();
}

#------------------------------------------------------------------------------

sub is_devel {
    my ($self) = @_;

    return $self->distribution->is_devel();
}

#------------------------------------------------------------------------------

sub is_eligible_for_index {
    my ($self) = @_;

    return $self->distribution->is_eligible_for_index();
}

#------------------------------------------------------------------------------

sub index_status {
    my ($self) = @_;

    return '-' if not $self->is_eligible_for_index();
    return '*' if $self->is_latest();
    return ' ';
}

#------------------------------------------------------------------------------

sub path {
    my ($self) = @_;

    return $self->distribution->path();
}

#------------------------------------------------------------------------------

sub version_numeric {
    my ($self) = @_;

    return $self->{__version_numeric__} ||=
        Pinto::Util::numify_version( $self->version() );
}

#------------------------------------------------------------------------------

sub to_string {
    my ($self) = @_;

    return $self->distribution->vname() . '/' . $self->vname();
}

#------------------------------------------------------------------------------

sub to_formatted_string {
    my ($self, $format) = @_;

    my %fspec = (
         'n' => sub { $self->name()                           },
         'N' => sub { $self->vname()                          },
         'v' => sub { $self->version()                        },
         'V' => sub { $self->version_numeric()                },
         'm' => sub { $self->is_devel()   ? 'D' : 'R'         },
         'x' => sub { $self->index_status()                   },
         'p' => sub { $self->distribution->path()             },
         'P' => sub { $self->distribution->native_path()      },
         'o' => sub { $self->is_local()   ? 'L' : 'F'         },
         'O' => sub { $self->distribution->origin()           },
         'a' => sub { $self->author()                         },
         'b' => sub { $self->is_blocked() ? 'B' : ' '         },
         'd' => sub { $self->distribution->name()             },
         'D' => sub { $self->distribution->vname()            },
         'w' => sub { $self->distribution->version()          },
         'W' => sub { $self->distribution->version_numeric()  },
         'u' => sub { $self->distribution->url()              },
    );

    $format ||= $self->default_format();
    return String::Format::stringf($format, %fspec);
}


#-------------------------------------------------------------------------------

sub default_format {
    my ($self) = @_;

    my $width = 38 - length $self->version();
    $width = length $self->name() if $width < length $self->name();

    return "%x%m%o %-${width}n %v  %p\n",
}

#-------------------------------------------------------------------------------

sub compare_version {
    my ($pkg_a, $pkg_b) = @_;

    throw_error "Cannot compare packages with different names: $pkg_a <=> $pkg_b"
        if $pkg_a->name() ne $pkg_b->name();

    my $r =   ( $pkg_a->is_local()          <=> $pkg_b->is_local()          )
           || ( $pkg_a->version_numeric()   <=> $pkg_b->version_numeric()   )
           || ( $pkg_a->distribution()      <=> $pkg_b->distribution()      );

    # No two packages can be considered equal!
    throw_error "Unable to determine ordering: $pkg_a <=> $pkg_b" if not $r;

    return $r;
};

#-------------------------------------------------------------------------------
1;

__END__
