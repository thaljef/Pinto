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

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 name

  data_type: 'text'
  is_nullable: 0

=head2 version

  data_type: 'text'
  is_nullable: 0

=head2 distribution

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "name",
  { data_type => "text", is_nullable => 0 },
  "version",
  { data_type => "text", is_nullable => 0 },
  "distribution",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<name_distribution_unique>

=over 4

=item * L</name>

=item * L</distribution>

=back

=cut

__PACKAGE__->add_unique_constraint("name_distribution_unique", ["name", "distribution"]);

=head1 RELATIONS

=head2 distribution

Type: belongs_to

Related object: L<Pinto::Schema::Result::Distribution>

=cut

__PACKAGE__->belongs_to(
  "distribution",
  "Pinto::Schema::Result::Distribution",
  { id => "distribution" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 registries

Type: has_many

Related object: L<Pinto::Schema::Result::Registry>

=cut

__PACKAGE__->has_many(
  "registries",
  "Pinto::Schema::Result::Registry",
  { "foreign.package" => "self.id" },
  { cascade_copy => 0, cascade_delete => 1 },
);


# Created by DBIx::Class::Schema::Loader v0.07015 @ 2012-04-27 00:51:37
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Q7XO23Z1jqeGK81NcPTHnA

#------------------------------------------------------------------------------

# ABSTRACT: Represents a Package provided by a Distribution

#------------------------------------------------------------------------------

use Carp;
use String::Format;

use overload ( '""'     => 'to_string',
               '<=>'    => 'compare',
               fallback => undef );

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------


__PACKAGE__->inflate_column( 'version' => { inflate => sub { version->parse($_[0]) },
                                            deflate => sub { $_[0]->stringify() } }
);

#------------------------------------------------------------------------------
# Schema::Loader does not create many-to-many relationships for us.  So we
# must create them by hand here...

__PACKAGE__->many_to_many( stacks => 'registry', 'stack' );


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
    my ($self, $format) = @_;

    my %fspec = (
         'n' => sub { $self->name()                                   },
         'N' => sub { $self->vname()                                  },
         'v' => sub { $self->version->stringify()                     },
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

    return '%a/%D/%N';  # AUTHOR/DIST-VNAME/PKG-VNAME
}

#-------------------------------------------------------------------------------

sub compare {
    my ($pkg_a, $pkg_b) = @_;

    confess "Can only compare Pinto::Package objects"
        if __PACKAGE__ ne ref $pkg_a || __PACKAGE__ ne ref $pkg_b;

    return 0 if $pkg_a->id() == $pkg_b->id();

    confess "Cannot compare packages with different names: $pkg_a <=> $pkg_b"
        if $pkg_a->name() ne $pkg_b->name();

    my $r =   ( $pkg_a->version()             <=> $pkg_b->version()             )
           || ( $pkg_a->distribution->mtime() <=> $pkg_b->distribution->mtime() );

    # No two non-identical packages can be considered equal!
    confess "Unable to determine ordering: $pkg_a <=> $pkg_b" if not $r;

    return $r;
};

#-------------------------------------------------------------------------------
1;

__END__
