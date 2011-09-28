package Pinto::Schema::Result::Distribution;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Pinto::Schema::Result::Distribution

=cut

__PACKAGE__->table("distribution");

=head1 ACCESSORS

=head2 distribution_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 path

  data_type: 'text'
  is_nullable: 0

=head2 origin

  data_type: 'text'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "distribution_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "path",
  { data_type => "text", is_nullable => 0 },
  "origin",
  { data_type => "text", is_nullable => 0 },
);
__PACKAGE__->set_primary_key("distribution_id");
__PACKAGE__->add_unique_constraint("path_unique", ["path"]);

=head1 RELATIONS

=head2 packages

Type: has_many

Related object: L<Pinto::Schema::Result::Package>

=cut

__PACKAGE__->has_many(
  "packages",
  "Pinto::Schema::Result::Package",
  { "foreign.distribution" => "self.distribution_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-09-25 13:47:31
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:6OrU0bGXWOnEWUIYJVnVzA

#-------------------------------------------------------------------------------

use URI;
use Path::Class;
use CPAN::DistnameInfo;

use Pinto::Util;
use Pinto::Exceptions qw(throw_error);

use overload ( '""'     => 'to_string',
               '<=>'    => 'compare_version',
               fallback => undef );

#------------------------------------------------------------------------------

sub new {
    my ($class, $attrs) = @_;

    $attrs->{origin} = 'LOCAL'
        if not defined $attrs->{origin};

    return $class->SUPER::new($attrs);
}

#------------------------------------------------------------------------------

sub name {
    my ($self) = @_;

    return $self->_distname_info->dist();
}

#------------------------------------------------------------------------------

sub vname {
    my ($self) = @_;

    return $self->_distname_info->distvname();
}

#------------------------------------------------------------------------------

sub version {
    my ($self) = @_;

    return $self->_distname_info->version();
}

#------------------------------------------------------------------------------

sub version_numeric {
    my ($self) = @_;

    return $self->{__version_numeric__} ||= do {

        eval { Pinto::Util::numify_version( $self->version() ) } || 0;
    };
}

#------------------------------------------------------------------------------

sub physical_path {
    my ($self, @base) = @_;

    my @parts = split '/', $self->path();

    return Path::Class::file(@base, qw(authors id), @parts);
}

#------------------------------------------------------------------------------

sub url {
    my ($self, $base) = @_;

    $base ||= $self->origin();

    return URI->new( "$base/authors/id/" . $self->path() )->canonical();
}

#------------------------------------------------------------------------------

sub is_devel {
    my ($self) = @_;

    return $self->_distname_info->maturity() eq 'developer';
}

#------------------------------------------------------------------------------

sub is_local {
    my ($self) = @_;

    return $self->origin() eq 'LOCAL';
}

#------------------------------------------------------------------------------

sub package_count {
    my ($self) = @_;

    return scalar $self->packages();
}

#------------------------------------------------------------------------------

sub to_string {
    my ($self) = @_;

    return $self->path();
}

#------------------------------------------------------------------------------

sub compare_version {
    my ($dist_a, $dist_b) = @_;

    throw_error "Cannot compare distributions with different names"
        if $dist_a->name() ne $dist_b->name();

    throw_error "Cannot compare development distribution $dist_a"
        if $dist_a->is_devel();

    throw_error "Cannot compare development distribution $dist_b"
        if $dist_b->is_devel();

    my $r =   ( $dist_a->is_local()         <=> $dist_b->is_local()        )
           || ( $dist_a->version_numeric()  <=> $dist_b->version_numeric() );

    # No two dists can be considered equal
    throw_error "Unable to compare $dist_a and $dist_b" if not $r;

    return $r;

}

#------------------------------------------------------------------------------

sub _distname_info {
    my ($self) = @_;

    return $self->{__distname_info__} ||= CPAN::DistnameInfo->new( $self->path() );

}

#------------------------------------------------------------------------------

1;

__END__
