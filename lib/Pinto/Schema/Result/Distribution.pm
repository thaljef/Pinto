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

=head2 md5

  data_type: 'text'
  is_nullable: 0

=head2 sha256

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
  "md5",
  { data_type => "text", is_nullable => 0 },
  "sha256",
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

=head1 RELATIONS

=head2 packages

Type: has_many

Related object: L<Pinto::Schema::Result::Package>

=cut

__PACKAGE__->has_many(
  "packages",
  "Pinto::Schema::Result::Package",
  { "foreign.distribution" => "self.id" },
  { cascade_copy => 0, cascade_delete => 1 },
);

=head2 prerequisites

Type: has_many

Related object: L<Pinto::Schema::Result::Prerequisite>

=cut

__PACKAGE__->has_many(
  "prerequisites",
  "Pinto::Schema::Result::Prerequisite",
  { "foreign.distribution" => "self.id" },
  { cascade_copy => 0, cascade_delete => 1 },
);

=head1 L<Moose> ROLES APPLIED

=over 4

=item * L<Pinto::Role::Schema::Result>

=back

=cut


with 'Pinto::Role::Schema::Result';


# Created by DBIx::Class::Schema::Loader v0.07015 @ 2012-05-09 09:12:08
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:HqbbygyiJcg0vCTHPiKzHw

#-------------------------------------------------------------------------------

# ABSTRACT: Represents a distribution archive

#-------------------------------------------------------------------------------

use URI;
use Path::Class;
use CPAN::DistnameInfo;
use String::Format;

use Pinto::Util;
use Pinto::Exception qw(throw);
use Pinto::DistributionSpec;

use overload ( '""' => 'to_string' );

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

sub FOREIGNBUILDARGS {
    my ($class, $args) = @_;

    $args ||= {};
    $args->{source} ||= 'LOCAL';

    return $args;
}

#------------------------------------------------------------------------------

sub register {
    my ($self, %args) = @_;

    my $stack = $args{stack};
    my $did_register = 0;
    my $errors       = 0;

    for my $pkg ($self->packages) {

      if (defined $pkg->registrations_rs->find( {stack => $stack->id} ) ) {
          $self->debug( sub {"Package $pkg is already on stack $stack"} );
          next;
      }

      my $incumbent = $stack->registration(package => $pkg->name);

      if (not $incumbent) {
          $self->debug(sub {"Registering $pkg on stack $stack"} );
          $pkg->register(stack => $stack);
          $did_register++;
          next;
      }

      my $incumbent_pkg = $incumbent->package;

      if ( $incumbent_pkg == $pkg ) {
        # TODO: should this be an exception?
        $self->warning("Package $pkg is already on stack $stack");
        next;
      }

      if ( $incumbent->is_pinned ) {
        my $pkg_name = $pkg->name;
        $self->error("Cannot add $pkg to stack $stack because $pkg_name is pinned to $incumbent_pkg");
        $errors++;
        next;
      }


      my ($log_as, $direction) = ($incumbent_pkg > $pkg) ? ('warning', 'Downgrading')
                                                         : ('notice',  'Upgrading');

      $incumbent->delete;
      $self->$log_as("$direction package $incumbent_pkg to $pkg in stack $stack");
      $pkg->register(stack => $stack);
      $did_register++;
    }

    throw "Unable to register distribution $self on stack $stack" if $errors;

    return $did_register;
}

#------------------------------------------------------------------------------

sub pin {
    my ($self, %args) = @_;

    my $stack   = $args{stack};
    my $errors  = 0;
    my $did_pin = 0;

    for my $pkg ($self->packages) {
        my $registration = $pkg->registration(stack => $stack);

        if (not $registration) {
            $self->error("Package $pkg is not registered on stack $stack");
            $errors++;
            next;
        }


        if ($registration->is_pinned) {
            $self->warning("Package $pkg is already pinned on stack $stack");
            next;
        }

        $registration->pin;
        $did_pin++;
    }

    throw "Unable to pin distribution $self to stack $stack" if $errors;

    return $did_pin;

}

#------------------------------------------------------------------------------

sub unpin {
    my ($self, %args) = @_;

    my $stack     = $args{stack};
    my $errors    = 0;
    my $did_unpin = 0;

    for my $pkg ($self->packages) {
        my $registration = $pkg->registration(stack => $stack);

        if (not $registration) {
            $self->error("Package $pkg is not registered on stack $stack");
            $errors++;
            next;
        }


        if (not $registration->is_pinned) {
            $self->warning("Package $pkg is not pinned on stack $stack");
            next;
        }

        $registration->unpin;
        $did_unpin++;
    }

    throw "Unable to unpin distribution $self to stack $stack" if $errors;

    return $did_unpin;
}

#------------------------------------------------------------------------------

has distname_info => (
    isa      => 'CPAN::DistnameInfo',
    init_arg => undef,
    handles  => { name     => 'dist',
                  vname    => 'distvname',
                  version  => 'version',
                  maturity => 'maturity' },
    default  => sub { CPAN::DistnameInfo->new( $_[0]->path ) },
    lazy     => 1,
);

#------------------------------------------------------------------------------

has is_devel => (
    is       => 'ro',
    isa      => 'Bool',
    init_arg => undef,
    default  => sub {$_[0]->maturity() eq 'developer'},
    lazy     => 1,
);

#------------------------------------------------------------------------------

sub path {
    my ($self) = @_;

    return join '/', substr($self->author, 0, 1),
                     substr($self->author, 0, 2),
                     $self->author,
                     $self->archive;
}

#------------------------------------------------------------------------------

sub native_path {
    my ($self, @base) = @_;

    return Path::Class::file( @base,
                              substr($self->author, 0, 1),
                              substr($self->author, 0, 2),
                              $self->author,
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

sub registered_packages {
    my ($self, %args) = @_;

    # TODO...
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

sub to_string {
    my ($self) = @_;

    return $self->author . '/' . $self->archive ;
}

#------------------------------------------------------------------------------

sub to_formatted_string {
    my ($self, $format) = @_;

    my %fspec = (
         'd' => sub { $self->name()                           },
         'D' => sub { $self->vname()                          },
         'w' => sub { $self->version()                        },
         'm' => sub { $self->is_devel()   ? 'd' : 'r'         },
         'p' => sub { $self->path()                           },
         'P' => sub { $self->native_path()                    },
         'f' => sub { $self->archive()                        },
         's' => sub { $self->is_local()   ? 'l' : 'f'         },
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

    return '%a/%f',
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------
1;

__END__
