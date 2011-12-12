use utf8;
package Pinto::Schema::Result::Package;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Pinto::Schema::Result::Package

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<package>

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
  default_value: null
  is_nullable: 1

=head2 is_pinned

  data_type: 'boolean'
  default_value: null
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
  { data_type => "boolean", default_value => \"null", is_nullable => 1 },
  "is_pinned",
  { data_type => "boolean", default_value => \"null", is_nullable => 1 },
  "distribution",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</package_id>

=back

=cut

__PACKAGE__->set_primary_key("package_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<name_distribution_unique>

=over 4

=item * L</name>

=item * L</distribution>

=back

=cut

__PACKAGE__->add_unique_constraint("name_distribution_unique", ["name", "distribution"]);

=head2 C<name_is_latest_unique>

=over 4

=item * L</name>

=item * L</is_latest>

=back

=cut

__PACKAGE__->add_unique_constraint("name_is_latest_unique", ["name", "is_latest"]);

=head2 C<name_is_pinned_unique>

=over 4

=item * L</name>

=item * L</is_pinned>

=back

=cut

__PACKAGE__->add_unique_constraint("name_is_pinned_unique", ["name", "is_pinned"]);

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


# Created by DBIx::Class::Schema::Loader v0.07014 @ 2011-12-06 11:04:23
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:xCWTZGqBqsFQCU96vVWt7w

#------------------------------------------------------------------------------

# ABSTRACT: Represents a package in a Distribution

#------------------------------------------------------------------------------

use Carp;
use String::Format;

use Pinto::Util;
use Pinto::Exceptions qw(throw_error);

use overload ( '""'     => 'to_string',
               '<=>'    => 'compare_version',
               fallback => undef );

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------


__PACKAGE__->inflate_column( 'version' => { inflate => sub { version->parse($_[0]) },
                                            deflate => sub { $_[0]->stringify() } }
);

#------------------------------------------------------------------------------

sub new {
    my ($class, $attrs) = @_;

    $attrs->{version} = 0
        if not defined $attrs->{version};

    return $class->SUPER::new($attrs);
}

#------------------------------------------------------------------------------

sub vname {
    my ($self) = @_;

    return $self->name() . '-' . $self->version();
}

#------------------------------------------------------------------------------

sub to_string {
    my ($self) = @_;

    # Some attributes are just undefined, usually because of
    # oddly named distributions and other old stuff on CPAN.
    no warnings 'uninitialized';  ## no critic qw(NoWarnings);

    return sprintf '%s/%s/%s', $self->distribution->author(),
                               $self->distribution->vname(),
                               $self->vname();
}

#------------------------------------------------------------------------------

sub to_formatted_string {
    my ($self, $format) = @_;

    my %fspec = (
         'n' => sub { $self->name()                                   },
         'N' => sub { $self->vname()                                  },
         'v' => sub { $self->version->stringify()                     },
         'x' => sub { $self->is_latest()                ? '@' : ' '   },
         'y' => sub { $self->is_pinned()                ? '+' : ' '   },
         'm' => sub { $self->distribution->is_devel()   ? 'd' : 'r'   },
         'p' => sub { $self->distribution->path()                     },
         'P' => sub { $self->distribution->archive()                  },
         's' => sub { $self->distribution->is_local()   ? 'l' : 'f'   },
         'S' => sub { $self->distribution->source()                   },
         'a' => sub { $self->distribution->author()                   },
         'd' => sub { $self->distribution->name()                     },
         'D' => sub { $self->distribution->vname()                    },
         'w' => sub { $self->distribution->version()                  },
         'u' => sub { $self->distribution->url()                      },
    );

    # Some attributes are just undefined, usually because of
    # oddly named distributions and other old stuff on CPAN.
    no warnings 'uninitialized';  ## no critic qw(NoWarnings);

    $format ||= $self->default_format();
    return String::Format::stringf($format, %fspec);
}


#-------------------------------------------------------------------------------

sub default_format {
    my ($self) = @_;

    my $width = 38 - length $self->version();
    $width = length $self->name() if $width < length $self->name();

    return "%x%m%s%y %-${width}n %v  %p\n",
}

#-------------------------------------------------------------------------------

sub compare_version {
    my ($pkg_a, $pkg_b) = @_;

    croak "Can only compare Pinto::Package objects"
        if __PACKAGE__ ne ref $pkg_a || __PACKAGE__ ne ref $pkg_b;

    croak "Cannot compare packages with different names: $pkg_a <=> $pkg_b"
        if $pkg_a->name() ne $pkg_b->name();

    my $r =   ( ($pkg_a->is_pinned() || 0)        <=> ($pkg_b->is_pinned() || 0)        )
           || ( $pkg_a->distribution->is_local()  <=> $pkg_b->distribution->is_local()  )
           || ( $pkg_a->version()                 <=> $pkg_b->version()                 )
           || ( $pkg_a->distribution->mtime()     <=> $pkg_b->distribution->mtime()     );

    # No two packages can be considered equal!
    throw_error "Unable to determine ordering: $pkg_a <=> $pkg_b" if not $r;

    return $r;
};

#-------------------------------------------------------------------------------
1;

__END__
