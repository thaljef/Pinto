use utf8;
package Pinto::Schema::Result::Distribution;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Pinto::Schema::Result::Distribution

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<distribution>

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

=head2 source

  data_type: 'text'
  is_nullable: 0

=head2 mtime

  data_type: 'integer'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "distribution_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "path",
  { data_type => "text", is_nullable => 0 },
  "source",
  { data_type => "text", is_nullable => 0 },
  "mtime",
  { data_type => "integer", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</distribution_id>

=back

=cut

__PACKAGE__->set_primary_key("distribution_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<path_unique>

=over 4

=item * L</path>

=back

=cut

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
  { cascade_copy => 0, cascade_delete => 1 },
);


# Created by DBIx::Class::Schema::Loader v0.07014 @ 2011-11-30 13:16:11
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:A9/6kPtFOxbhExC2ncsT5Q

#-------------------------------------------------------------------------------

# ABSTRACT: Represents a distribution archive

#-------------------------------------------------------------------------------

use URI;
use Path::Class;
use CPAN::DistnameInfo;
use String::Format;

use Pinto::Util;
use Pinto::Exceptions qw(throw_error);

use overload ( '""' => 'to_string' );

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

sub new {
    my ($class, $attrs) = @_;

    $attrs->{source} = 'LOCAL'
        if not defined $attrs->{source};

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

sub archive {
    my ($self, @base) = @_;

    my @parts = split '/', $self->path();

    return Path::Class::file(@base, qw(authors id), @parts);
}

#------------------------------------------------------------------------------

sub author {
    my ($self) = @_;

    my $dist_path = $self->path();

    return (split '/', $dist_path)[2];
}

#------------------------------------------------------------------------------

sub url {
    my ($self, $base) = @_;

    # TODO: can we come up with a sensible URL for local dists?
    return 'UNKNOWN' if $self->is_local();

    $base ||= $self->source();

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

    return $self->source() eq 'LOCAL';
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

sub to_formatted_string {
    my ($self, $format) = @_;

    my %fspec = (
         'd' => sub { $self->name()                           },
         'D' => sub { $self->vname()                          },
         'w' => sub { $self->version()                        },
         'm' => sub { $self->is_devel()   ? 'D' : 'R'         },
         'p' => sub { $self->path()                           },
         'P' => sub { $self->archive()                        },
         's' => sub { $self->is_local()   ? 'L' : 'F'         },
         'S' => sub { $self->source()                         },
         'a' => sub { $self->author()                         },
         'u' => sub { $self->url()                            },
         'c' => sub { $self->package_count()                  },
    );

    $format ||= $self->default_format();
    return String::Format::stringf($format, %fspec);
}

#-------------------------------------------------------------------------------

sub default_format {
    my ($self) = @_;

    return '%p',
}

#------------------------------------------------------------------------------

sub _distname_info {
    my ($self) = @_;

    return $self->{__distname_info__} ||= CPAN::DistnameInfo->new( $self->path() );

}

#------------------------------------------------------------------------------

1;

__END__
