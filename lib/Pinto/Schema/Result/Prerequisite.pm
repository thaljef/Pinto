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
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "phase",
  { data_type => "text", is_nullable => 0 },
  "distribution",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "package_name",
  { data_type => "text", is_nullable => 0 },
  "package_version",
  { data_type => "text", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<distribution_package_name_unique>

=over 4

=item * L</distribution>

=item * L</package_name>

=back

=cut

__PACKAGE__->add_unique_constraint(
  "distribution_package_name_unique",
  ["distribution", "package_name"],
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

=head1 L<Moose> ROLES APPLIED

=over 4

=item * L<Pinto::Role::Schema::Result>

=back

=cut


with 'Pinto::Role::Schema::Result';


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-03-25 16:02:38
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:LymPuQXtJzdbuIx4nmxtQg

#------------------------------------------------------------------------------

# ABSTRACT: Represents a Distribution -> Package dependency

#------------------------------------------------------------------------------

use Pinto::PackageSpec;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

sub sqlt_deploy_hook {
    my ($self, $sqlt_table) = @_;
 
    $sqlt_table->add_index(name => 'prerequisite_idx_package_name', fields => ['package_name']);

    return;
}

#------------------------------------------------------------------------------
# NOTE: We often convert a Prerequsite to/from a PackageSpec object. They don't
# use quite the same names for their attributes, so we shuffle them around here.

sub FOREIGNBUILDARGS {
    my ($class, $args) = @_;

    $args ||= {};
    $args->{package_name}      = delete $args->{name};
    $args->{package_version}   = delete $args->{version};

    return $args;
}

#------------------------------------------------------------------------------

sub as_spec {
    my ($self) = @_;

    return Pinto::PackageSpec->new( name    => $self->package_name,
                                    version => $self->package_version );
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------
1;

__END__
