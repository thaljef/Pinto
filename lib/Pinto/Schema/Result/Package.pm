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

use version;

use overload ( '""'     => 'to_string',
               '<=>'    => 'compare_version',
               fallback => undef );

use Pinto::Util;
use Pinto::Comparator;

use Exception::Class::TryCatch;

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

    return    Pinto::Util::is_devel_version( $self->version() )
           || $self->distribution->is_devel();
}

#------------------------------------------------------------------------------

sub path {
    my ($self) = @_;

    return $self->distribution->path();
}

#------------------------------------------------------------------------------

sub version_numeric {
    my ($self) = @_;

    return $self->{__version_numeric__} ||= do {

        eval { Pinto::Util::numify_version( $self->version() ) } || 0;
    };
}

#------------------------------------------------------------------------------

sub to_string {
    my ($self) = @_;

    return $self->vname();
}

#------------------------------------------------------------------------------

sub to_formatted_string {
    my ($self) = @_;

    my $latest  = $self->is_latest()    ? '*' : ' ';
    my $local   = $self->is_local()     ? 'L' : 'F';
    my $mature  = $self->is_devel()     ? 'D' : 'R';

    my $width = 38 - length $self->version();
    $width = length $self->name() if $width < length $self->name();

    return sprintf "%s%s%s %-${width}s %s  %s\n",
       $latest, $local, $mature, $self->name(), $self->version(), $self->path();
}

#-------------------------------------------------------------------------------

sub compare_version {
    my ($self, $other) = @_;

    return Pinto::Comparator->compare_packages($self, $other);
}

#-------------------------------------------------------------------------------
1;

__END__
