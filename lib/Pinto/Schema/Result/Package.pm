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

=head2 should_index

  data_type: 'boolean'
  default_value: 0
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
  "version_numeric",
  { data_type => "real", is_nullable => 0 },
  "should_index",
  { data_type => "boolean", default_value => 0, is_nullable => 1 },
  "distribution",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);
__PACKAGE__->set_primary_key("package_id");
__PACKAGE__->add_unique_constraint("name_should_index_unique", ["name", "should_index"]);
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


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-09-23 01:24:07
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ZlKBI3WNulfONRVzU6HSWA

#------------------------------------------------------------------------------

use overload ( '<=>' => 'compare_version',
               'cmp' => 'compare_name',
               '""'  => 'to_string' );

use Pinto::Util;

use Exception::Class::TryCatch;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

sub new {
    my ($class, $attrs) = @_;

    $attrs->{version_numeric} =
        eval { Pinto::Util::numify_version($attrs->{version}) };

    if (catch my $e, ['Pinto::Exception::IllegalVersion']) {
        warn "$attrs->{name}: $e. Forcing it to 0\n";
        $attrs->{version_numeric} = 0;
    }

    return $class->SUPER::new($attrs);
}

#------------------------------------------------------------------------------

sub author {
    my ($self) = @_;

    my $dist_path = $self->distribution->path();

    return (split '/', $dist_path)[2];
}

#------------------------------------------------------------------------------

sub is_local {
    my ($self) = @_;

    return $self->distribution->is_local();
}

#------------------------------------------------------------------------------

sub is_devel {
    my ($self) = @_;

    return    $self->distribution->is_devel()
           || Pinto::Util::is_devel_version( $self->version() );
}

#------------------------------------------------------------------------------

sub path {
    my ($self) = @_;

    return $self->distribution->path();
}

#------------------------------------------------------------------------------

sub to_string {
    my ($self) = @_;

    return $self->name();
}

#------------------------------------------------------------------------------

sub to_long_string {
    my ($self) = @_;

    my $indexed = $self->should_index() ? '*' : ' ';
    my $local   = $self->is_local()     ? 'L' : 'F';
    my $mature  = $self->is_devel()     ? 'D' : 'R';

    my $width = 38 - length $self->version();
    $width = length $self->name() if $width < length $self->name();

    return sprintf "%s%s%s %-${width}s %s  %s\n",
       $indexed, $local, $mature, $self->name(), $self->version(), $self->path();
}

#-------------------------------------------------------------------------------

sub compare_version {
    my ($self, $other, $swap) = @_;
    ($other, $self) = ($self, $other) if $swap;

    return    ( $self->is_local()        <=> $other->is_local()         )
           || ( $self->version_numeric() <=> $other->version_numeric()  );
}

#-------------------------------------------------------------------------------

sub compare_name {
    my ($self, $other, $swap) = @_;
    ($other, $self) = ($self, $other) if $swap;

    return  $self->name() cmp $other->name();
}

#-------------------------------------------------------------------------------
1;

__END__
