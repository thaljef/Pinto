use utf8;

package Pinto::Schema::Result::Package;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Pinto::Schema::Result::Package

=cut

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

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

=head2 file

  data_type: 'text'
  default_value: null
  is_nullable: 1

=head2 sha256

  data_type: 'text'
  default_value: null
  is_nullable: 1

=head2 distribution

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
    "id", { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
    "name",         { data_type => "text",    is_nullable    => 0 },
    "version",      { data_type => "text",    is_nullable    => 0 },
    "file",         { data_type => "text",    default_value  => \"null", is_nullable => 1 },
    "sha256",       { data_type => "text",    default_value  => \"null", is_nullable => 1 },
    "distribution", { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
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

__PACKAGE__->add_unique_constraint( "name_distribution_unique", [ "name", "distribution" ] );

=head1 RELATIONS

=head2 distribution

Type: belongs_to

Related object: L<Pinto::Schema::Result::Distribution>

=cut

__PACKAGE__->belongs_to(
    "distribution",
    "Pinto::Schema::Result::Distribution",
    { id            => "distribution" },
    { is_deferrable => 0, on_delete => "CASCADE", on_update => "NO ACTION" },
);

=head2 registrations

Type: has_many

Related object: L<Pinto::Schema::Result::Registration>

=cut

__PACKAGE__->has_many(
    "registrations", "Pinto::Schema::Result::Registration",
    { "foreign.package" => "self.id" }, { cascade_copy => 0, cascade_delete => 0 },
);

=head1 L<Moose> ROLES APPLIED

=over 4

=item * L<Pinto::Role::Schema::Result>

=back

=cut

with 'Pinto::Role::Schema::Result';

# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-03-04 12:39:54
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:wYrDViIlHDocM5byRBn1Qg

#------------------------------------------------------------------------------

# ABSTRACT: Represents a Package provided by a Distribution

#------------------------------------------------------------------------------

use String::Format;

use Pinto::PackageSpec;
use Pinto::Util qw(itis throw);

use overload (
    '""'     => 'to_string',
    '<=>'    => 'numeric_compare',
    'cmp'    => 'string_compare',
    fallback => undef
);

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

__PACKAGE__->inflate_column(
    'version' => {
        inflate => sub { version->parse( $_[0] ) },
        deflate => sub { $_[0]->stringify() },
    }
);

#------------------------------------------------------------------------------
# Schema::Loader does not create many-to-many relationships for us.  So we
# must create them by hand here...

__PACKAGE__->many_to_many( revisions => 'registration', 'revision' );

#------------------------------------------------------------------------------

sub FOREIGNBUILDARGS {
    my ( $class, $args ) = @_;

    $args ||= {};
    $args->{version} = 0 if not defined $args->{version};

    return $args;
}

#------------------------------------------------------------------------------

sub register {
    my ( $self, %args ) = @_;

    my $stack = $args{stack};
    my $pin   = $args{pin};

    my $struct = {
        revision     => $stack->head->id,
        is_pinned    => $pin,
        package_name => $self->name,
        distribution => $self->get_column('distribution')
    };

    $self->create_related( registrations => $struct );

    return $self;
}

#------------------------------------------------------------------------------

sub vname {
    my ($self) = @_;

    return $self->name . '~' . $self->version;
}

#------------------------------------------------------------------------------

sub as_spec {
    my ($self) = @_;

    return Pinto::PackageSpec->new(
        name    => $self->name,
        version => $self->version
    );
}

#------------------------------------------------------------------------------

sub to_string {
    my ( $self, $format ) = @_;

    # my ($pkg, $file, $line) = caller;
    # warn __PACKAGE__ . " stringified from $file at line $line";

    my %fspec = (
        'p' => sub { $self->name() },
        'P' => sub { $self->vname() },
        'v' => sub { $self->version->stringify() },
        'm' => sub { $self->distribution->is_devel() ? 'd' : 'r' },
        'h' => sub { $self->distribution->path() },
        'H' => sub { $self->distribution->native_path() },
        'f' => sub { $self->distribution->archive },
        's' => sub { $self->distribution->is_local() ? 'l' : 'f' },
        'S' => sub { $self->distribution->source() },
        'a' => sub { $self->distribution->author() },
        'd' => sub { $self->distribution->name() },
        'D' => sub { $self->distribution->vname() },
        'V' => sub { $self->distribution->version() },
        'u' => sub { $self->distribution->url() },
    );

    # Some attributes are just undefined, usually because of
    # oddly named distributions and other old stuff on CPAN.
    no warnings 'uninitialized';    ## no critic qw(NoWarnings);

    $format ||= $self->default_format();
    return String::Format::stringf( $format, %fspec );
}

#-------------------------------------------------------------------------------

sub default_format {
    my ($self) = @_;

    return '%a/%D/%P';              # AUTHOR/DIST_VNAME/PKG_VNAME
}

#-------------------------------------------------------------------------------

sub numeric_compare {
    my ( $pkg_a, $pkg_b ) = @_;

    my $pkg = __PACKAGE__;
    throw "Can only compare $pkg objects"
        if not( itis( $pkg_a, $pkg ) && itis( $pkg_b, $pkg ) );

    return 0 if $pkg_a->id == $pkg_b->id;

    throw "Cannot compare packages with different names: $pkg_a <=> $pkg_b"
        if $pkg_a->name ne $pkg_b->name;

    my $r = ( $pkg_a->version <=> $pkg_b->version )
        || ( $pkg_a->distribution->mtime <=> $pkg_b->distribution->mtime );

    # No two non-identical packages can be considered equal!
    throw "Unable to determine ordering: $pkg_a <=> $pkg_b" if not $r;

    return $r;
}

#-------------------------------------------------------------------------------

sub string_compare {
    my ( $pkg_a, $pkg_b ) = @_;

    my $pkg = __PACKAGE__;
    throw "Can only compare $pkg objects"
        if not( itis( $pkg_a, $pkg ) && itis( $pkg_b, $pkg ) );

    return 0 if $pkg_a->id() == $pkg_b->id();

    my $r = ( $pkg_a->name cmp $pkg_b->name )
        || ( $pkg_a->version <=> $pkg_b->version );

    return $r;
}

#-------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#-------------------------------------------------------------------------------
1;

__END__

