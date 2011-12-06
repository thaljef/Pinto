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


# Created by DBIx::Class::Schema::Loader v0.07014 @ 2011-12-06 11:01:04
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:oaRV9jWYq0VgLnIU/he+sA
# These lines were loaded from '/Users/jeff/opt/local/lib/perl5/site_perl/5.14.1/Pinto/Schema/Result/Distribution.pm' found in @INC.
# They are now part of the custom portion of this file
# for you to hand-edit.  If you do not either delete
# this section or remove that file from @INC, this section
# will be repeated redundantly when you re-create this
# file again via Loader!  See skip_load_external to disable
# this feature.

use utf8;
package Pinto::Schema::Result::Distribution;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE


use strict;
use warnings;

use base 'DBIx::Class::Core';


__PACKAGE__->table("distribution");


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


__PACKAGE__->set_primary_key("distribution_id");


__PACKAGE__->add_unique_constraint("path_unique", ["path"]);


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

our $VERSION = '0.025_003'; # VERSION

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



=pod

=for :stopwords Jeffrey Ryan Thalhammer Imaginative Software Systems

=head1 NAME

Pinto::Schema::Result::Distribution - Represents a distribution archive

=head1 VERSION

version 0.025_003

=head1 NAME

Pinto::Schema::Result::Distribution

=head1 TABLE: C<distribution>

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

=head1 PRIMARY KEY

=over 4

=item * L</distribution_id>

=back

=head1 UNIQUE CONSTRAINTS

=head2 C<path_unique>

=over 4

=item * L</path>

=back

=head1 RELATIONS

=head2 packages

Type: has_many

Related object: L<Pinto::Schema::Result::Package>

=head1 AUTHOR

Jeffrey Ryan Thalhammer <jeff@imaginative-software.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Imaginative Software Systems.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__
# End of lines loaded from '/Users/jeff/opt/local/lib/perl5/site_perl/5.14.1/Pinto/Schema/Result/Distribution.pm' 

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
