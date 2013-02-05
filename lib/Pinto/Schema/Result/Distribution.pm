use utf8;
package Pinto::Schema::Result::Distribution;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Pinto::Schema::Result::Distribution

=cut

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

=head1 TABLE: C<distribution>

=cut

__PACKAGE__->table("distribution");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 author

  data_type: 'text'
  is_nullable: 0

=head2 archive

  data_type: 'text'
  is_nullable: 0

=head2 source

  data_type: 'text'
  is_nullable: 0

=head2 mtime

  data_type: 'integer'
  is_nullable: 0

=head2 sha256

  data_type: 'text'
  is_nullable: 0

=head2 md5

  data_type: 'text'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "author",
  { data_type => "text", is_nullable => 0 },
  "archive",
  { data_type => "text", is_nullable => 0 },
  "source",
  { data_type => "text", is_nullable => 0 },
  "mtime",
  { data_type => "integer", is_nullable => 0 },
  "sha256",
  { data_type => "text", is_nullable => 0 },
  "md5",
  { data_type => "text", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<author_archive_unique>

=over 4

=item * L</author>

=item * L</archive>

=back

=cut

__PACKAGE__->add_unique_constraint("author_archive_unique", ["author", "archive"]);

=head2 C<md5_unique>

=over 4

=item * L</md5>

=back

=cut

__PACKAGE__->add_unique_constraint("md5_unique", ["md5"]);

=head2 C<sha256_unique>

=over 4

=item * L</sha256>

=back

=cut

__PACKAGE__->add_unique_constraint("sha256_unique", ["sha256"]);

=head1 RELATIONS

=head2 packages

Type: has_many

Related object: L<Pinto::Schema::Result::Package>

=cut

__PACKAGE__->has_many(
  "packages",
  "Pinto::Schema::Result::Package",
  { "foreign.distribution" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 prerequisites

Type: has_many

Related object: L<Pinto::Schema::Result::Prerequisite>

=cut

__PACKAGE__->has_many(
  "prerequisites",
  "Pinto::Schema::Result::Prerequisite",
  { "foreign.distribution" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head1 L<Moose> ROLES APPLIED

=over 4

=item * L<Pinto::Role::Schema::Result>

=back

=cut


with 'Pinto::Role::Schema::Result';


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-02-04 11:03:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:c2P+pLq6KzLZMTiBMNZg9g

#-------------------------------------------------------------------------------

# ABSTRACT: Represents a distribution archive

#-------------------------------------------------------------------------------

use MooseX::Types::Moose qw(Str Bool);

use URI;
use Path::Class;
use CPAN::DistnameInfo;
use String::Format;

use Pinto::Util qw(itis);
use Pinto::Exception qw(throw);
use Pinto::DistributionSpec;

use overload ( '""'  => 'to_string',
               'cmp' => 'string_compare');

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

sub sqlt_deploy_hook {
    my ($self, $sqlt_table) = @_;
 
    $sqlt_table->add_index(name => 'distribution_idx_author', fields => ['author']);

    return;
}

#------------------------------------------------------------------------------

sub FOREIGNBUILDARGS {
    my ($class, $args) = @_;

    $args ||= {};
    $args->{source} ||= 'LOCAL';

    return $args;
}

#------------------------------------------------------------------------------

has distname_info => (
    isa      => 'CPAN::DistnameInfo',
    init_arg => undef,
    handles  => { name     => 'dist',
                  vname    => 'distvname',
                  version  => 'version',
                  maturity => 'maturity'},
    default  => sub { CPAN::DistnameInfo->new( $_[0]->path ) },
    lazy     => 1,
);


has is_devel => (
    is       => 'ro',
    isa      => Bool,
    init_arg => undef,
    default  => sub {$_[0]->maturity() eq 'developer'},
    lazy     => 1,
);


has author_canonical => (
    is       => 'ro',
    isa      => Str,
    init_arg => undef,
    default  => sub {uc $_[0]->author},
    lazy     => 1,
);

#------------------------------------------------------------------------------

sub path {
    my ($self) = @_;

    return join '/', substr($self->author_canonical, 0, 1),
                     substr($self->author_canonical, 0, 2),
                     $self->author_canonical,
                     $self->archive;
}

#------------------------------------------------------------------------------

sub native_path {
    my ($self, @base) = @_;

    return Path::Class::file( @base,
                              substr($self->author_canonical, 0, 1),
                              substr($self->author_canonical, 0, 2),
                              $self->author_canonical,
                              $self->archive );
}

#------------------------------------------------------------------------------

sub url {
    my ($self, $base) = @_;

    # TODO: Is there a sensible URL for local dists?
    return 'UNKNOWN' if $self->is_local;

    $base ||= $self->source;

    return URI->new( "$base/authors/id/" . $self->path )->canonical;
}

#------------------------------------------------------------------------------

sub is_local {
    my ($self) = @_;

    return $self->source eq 'LOCAL';
}

#------------------------------------------------------------------------------

sub package {
    my ($self, %args) = @_;

    my $pkg_name = $args{name};

    my $where = {name => $pkg_name};
    my $attrs = {key => 'name_distribution_unique'};
    my $pkg = $self->find_related('packages', $where, $attrs) or return;

    if (my $stk_name = $args{stack}){
        return $pkg->registration(stack => $stk_name) ? $pkg : ();
    }

    return $pkg;
}

#------------------------------------------------------------------------------

sub package_count {
    my ($self) = @_;

    return scalar $self->packages;
}

#------------------------------------------------------------------------------

sub prerequisite_specs {
    my ($self) = @_;

    return map { $_->as_spec } $self->prerequisites;
}

#------------------------------------------------------------------------------

sub as_spec {
    my ($self) = @_;

    return Pinto::DistributionSpec->new(path => $self->path);
}

#------------------------------------------------------------------------------

sub string_compare {
    my ($dist_a, $dist_b) = @_;

    my $pkg = __PACKAGE__;
    throw "Can only compare $pkg objects"
        if not ( itis($dist_a, $pkg) && itis($dist_b, $pkg) );

    return 0 if $dist_a->id == $dist_b->id;

    my $r =   ($dist_a->author_canonical cmp $dist_b->author_canonical)
           || ($dist_a->archive          cmp $dist_b->archive);

    return $r;
}

#------------------------------------------------------------------------------

sub to_string {
    my ($self, $format) = @_;

    my %fspec = (
         'd' => sub { $self->name()                           },
         'D' => sub { $self->vname()                          },
         'V' => sub { $self->version()                        },
         'm' => sub { $self->is_devel()   ? 'd' : 'r'         },
         'h' => sub { $self->path()                           },
         'H' => sub { $self->native_path()                    },
         'f' => sub { $self->archive()                        },
         's' => sub { $self->is_local()   ? 'l' : 'f'         },
         'S' => sub { $self->source()                         },
         'a' => sub { $self->author()                         },
         'A' => sub { $self->author_canonical()               },
         'u' => sub { $self->url()                            },
         'c' => sub { $self->package_count()                  },
    );

    $format ||= $self->default_format();
    return String::Format::stringf($format, %fspec);
}

#-------------------------------------------------------------------------------

sub default_format {
    my ($self) = @_;

    return '%A/%f', # AUTHOR/Dist-Name-1.0.tar.gz
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------
1;

__END__
