use utf8;

package Pinto::Schema::Result::Prerequisite;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Pinto::Schema::Result::Prerequisite

=cut

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

=head1 TABLE: C<prerequisite>

=cut

__PACKAGE__->table("prerequisite");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 phase

  data_type: 'text'
  is_nullable: 0

=head2 distribution

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 package_name

  data_type: 'text'
  is_nullable: 0

=head2 package_version

  data_type: 'text'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
    "id", { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
    "phase",           { data_type => "text",    is_nullable    => 0 },
    "distribution",    { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
    "package_name",    { data_type => "text",    is_nullable    => 0 },
    "package_version", { data_type => "text",    is_nullable    => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<distribution_phase_package_name_unique>

=over 4

=item * L</distribution>

=item * L</phase>

=item * L</package_name>

=back

=cut

__PACKAGE__->add_unique_constraint(
    "distribution_phase_package_name_unique",
    [ "distribution", "phase", "package_name" ],
);

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

=head1 L<Moose> ROLES APPLIED

=over 4

=item * L<Pinto::Role::Schema::Result>

=back

=cut

with 'Pinto::Role::Schema::Result';

# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-03-26 11:05:47
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:p++Wil511AYW5fZ8Xoe4Jg

#------------------------------------------------------------------------------

# ABSTRACT: Represents a Distribution -> Package dependency

#------------------------------------------------------------------------------

use Pinto::Target::Package;

use overload ( '""' => 'to_string' );

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------
# NOTE: We often convert a Prerequsite to/from a PackageSpec object. They don't
# use quite the same names for their attributes, so we shuffle them around here.

sub FOREIGNBUILDARGS {
    my ( $class, $args ) = @_;

    $args ||= {};
    $args->{package_name}    = delete $args->{name};
    $args->{package_version} = delete $args->{version};

    return $args;
}

#------------------------------------------------------------------------------

has as_target => (
    is       => 'ro',
    isa      => 'Pinto::Target::Package',
    init_arg => undef,
    lazy     => 1,
    handles  => [qw(is_core is_perl)],
    default  => sub {
        Pinto::Target::Package->new(
            name    => $_[0]->package_name,
            version => $_[0]->package_version
        );
    },
);

#------------------------------------------------------------------------------

sub to_string {
    my ($self) = @_;

    return $self->as_target->to_string;
}

#------------------------------------------------------------------------------

for my $phase ( qw(configure build test runtime develop) ) {
    no strict 'refs';
    *{__PACKAGE__ . "::is_$phase"} = sub {shift->phase eq $phase};
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------
1;

__END__
