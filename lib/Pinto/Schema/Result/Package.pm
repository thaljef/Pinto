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

=head2 version_numeric

  data_type: 'real'
  is_nullable: 0

=head2 distribution

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "package_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "name",
  { data_type => "text", is_nullable => 0 },
  "version",
  { data_type => "text", is_nullable => 0 },
  "version_numeric",
  { data_type => "real", is_nullable => 0 },
  "distribution",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
);
__PACKAGE__->set_primary_key("package_id");
__PACKAGE__->add_unique_constraint(
  "name_version_distribution_unique",
  ["name", "version", "distribution"],
);

=head1 RELATIONS

=head2 distribution

Type: belongs_to

Related object: L<Pinto::Schema::Result::Distribution>

=cut

__PACKAGE__->belongs_to(
  "distribution",
  "Pinto::Schema::Result::Distribution",
  { distribution_id => "distribution" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-09-17 23:28:29
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:BNhxA8CIEG2724q0bKkpDQ

#------------------------------------------------------------------------------

=method to_string()

Returns this Package as a string containing the package name.  This is
what you get when you evaluate and Package in double quotes.

=cut

sub to_string {
    my ($self) = @_;

    return $self->name();
}

#------------------------------------------------------------------------------

=method to_index_string()

Returns this Package object as a string that is suitable for writing
to an F<02packages.details.txt> file.

=cut

sub to_index_string {
    my ($self) = @_;

    my $width = 38 - length $self->version();
    $width = length $self->name() if $width < length $self->name();

    return sprintf "%-${width}s %s  %s\n", $self->name(),
                                           $self->version(),
                                           $self->distribution->location();
}

#-------------------------------------------------------------------------------
1;

__END__
