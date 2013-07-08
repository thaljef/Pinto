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

=head2 revision

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 package_name

  data_type: 'text'
  is_nullable: 0

=head2 package

  data_type: 'integer'
  is_foreign_key: 1
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
    "id",       { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
    "revision", { data_type => "integer", is_foreign_key    => 1, is_nullable => 0 },
    "package_name", { data_type => "text",    is_nullable    => 0 },
    "package",      { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
    "distribution", { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
    "is_pinned",    { data_type => "boolean", is_nullable    => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<revision_package_name_unique>

=over 4

=item * L</revision>

=item * L</package_name>

=back

=cut

__PACKAGE__->add_unique_constraint( "revision_package_name_unique", [ "revision", "package_name" ] );

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

=head2 package

Type: belongs_to

Related object: L<Pinto::Schema::Result::Package>

=cut

__PACKAGE__->belongs_to(
    "package",
    "Pinto::Schema::Result::Package",
    { id            => "package" },
    { is_deferrable => 0, on_delete => "CASCADE", on_update => "NO ACTION" },
);

=head2 revision

Type: belongs_to

Related object: L<Pinto::Schema::Result::Revision>

=cut

__PACKAGE__->belongs_to(
    "revision",
    "Pinto::Schema::Result::Revision",
    { id            => "revision" },
    { is_deferrable => 0, on_delete => "CASCADE", on_update => "NO ACTION" },
);

=head1 L<Moose> ROLES APPLIED

=over 4

=item * L<Pinto::Role::Schema::Result>

=back

=cut

with 'Pinto::Role::Schema::Result';

# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-03-04 12:39:54
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:AkBHZ7hQ0BdZdv0DoCJufA

#------------------------------------------------------------------------------

# ABSTRACT: Represents the relationship between a Package and a Stack

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

use String::Format;

use Pinto::Util qw(itis throw);

use overload (
    '""'     => 'to_string',
    'cmp'    => 'string_compare',
    '<=>'    => 'numeric_compare',
    fallback => undef
);

#-------------------------------------------------------------------------------

sub FOREIGNBUILDARGS {
    my ( $class, $args ) = @_;

    # Should we default these here or in the database?

    $args ||= {};
    $args->{is_pinned} ||= 0;

    return $args;
}

#-------------------------------------------------------------------------------

sub update { throw 'PANIC: Update to registrations are not allowed' }

#-------------------------------------------------------------------------------

sub pin {
    my ($self) = @_;

    throw "$self is already pinned" if $self->is_pinned;

    $self->delete;
    my $copy = $self->copy( { is_pinned => 1 } );

    return $copy;
}

#-------------------------------------------------------------------------------

sub unpin {
    my ($self) = @_;

    throw "$self is not pinned" if not $self->is_pinned;

    $self->delete;
    my $copy = $self->copy( { is_pinned => 0 } );

    return $copy;
}

#-------------------------------------------------------------------------------

sub numeric_compare {
    my ( $reg_a, $reg_b ) = @_;

    my $pkg = __PACKAGE__;
    throw "Can only compare $pkg objects"
        if not( itis( $reg_a, $pkg ) && itis( $reg_b, $pkg ) );

    return 0 if $reg_a->id == $reg_b->id;

    return $reg_a->package <=> $reg_b->package;
}

#------------------------------------------------------------------------------

sub string_compare {
    my ( $reg_a, $reg_b ) = @_;

    my $class = __PACKAGE__;
    throw "Can only compare $class objects"
        if not( itis( $reg_a, $class ) && itis( $reg_b, $class ) );

    return 0 if $reg_a->id == $reg_b->id;

    return
           ( $reg_a->package->distribution->author cmp $reg_b->package->distribution->author )
        || ( $reg_a->package->distribution->vname cmp $reg_b->package->distribution->vname )
        || ( $reg_a->package->vname cmp $reg_b->package->vname );
}

#------------------------------------------------------------------------------

sub flags {
    my ($self) = @_;

    my $format = '%m%s%y';
    return $self->to_string($format);
}

#------------------------------------------------------------------------------

sub to_string {
    my ( $self, $format ) = @_;

    # my ($pkg, $file, $line) = caller;
    # warn __PACKAGE__ . " stringified from $file at line $line";

    my %fspec = (
        p => sub { $self->package->name },
        P => sub { $self->package->vname },
        v => sub { $self->package->version },
        y => sub { $self->is_pinned ? '!' : '-' },
        m => sub { $self->distribution->is_devel ? 'd' : 'r' },
        h => sub { $self->distribution->path },
        H => sub { $self->distribution->native_path },
        f => sub { $self->distribution->archive },
        s => sub { $self->distribution->is_local ? 'l' : 'f' },
        S => sub { $self->distribution->source },
        a => sub { $self->distribution->author },
        d => sub { $self->distribution->name },
        D => sub { $self->distribution->vname },
        V => sub { $self->distribution->version },
        u => sub { $self->distribution->url },
        i => sub { $self->revision->uuid_prefix },
        F => sub { $self->flags },
    );

    # Some attributes are just undefined, usually because of
    # oddly named distributions and other old stuff on CPAN.
    no warnings 'uninitialized';    ## no critic qw(NoWarnings);

    $format ||= $self->default_format();
    return String::Format::stringf( $format, %fspec );
}

#-------------------------------------------------------------------------------

sub default_format {

    return '%a/%D/%P/%y';           # AUTHOR/DIST_VNAME/PKG_VNAME/PIN_STATUS
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------
1;

__END__
