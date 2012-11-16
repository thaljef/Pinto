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

=head2 author_canonical

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
  "author_canonical",
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

=head2 C<author_canonical_archive_unique>

=over 4

=item * L</author_canonical>

=item * L</archive>

=back

=cut

__PACKAGE__->add_unique_constraint(
  "author_canonical_archive_unique",
  ["author_canonical", "archive"],
);

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

=head2 registration_changes

Type: has_many

Related object: L<Pinto::Schema::Result::RegistrationChange>

=cut

__PACKAGE__->has_many(
  "registration_changes",
  "Pinto::Schema::Result::RegistrationChange",
  { "foreign.distribution" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 registrations

Type: has_many

Related object: L<Pinto::Schema::Result::Registration>

=cut

__PACKAGE__->has_many(
  "registrations",
  "Pinto::Schema::Result::Registration",
  { "foreign.distribution" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head1 L<Moose> ROLES APPLIED

=over 4

=item * L<Pinto::Role::Schema::Result>

=back

=cut


with 'Pinto::Role::Schema::Result';


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2012-11-12 10:50:21
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ANnPDZEqb47L28lc94IxxA

#-------------------------------------------------------------------------------

# ABSTRACT: Represents a distribution archive

#-------------------------------------------------------------------------------

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

sub FOREIGNBUILDARGS {
    my ($class, $args) = @_;

    $args ||= {};
    $args->{source} ||= 'LOCAL';
    $args->{author_canonical} = uc $args->{author};

    return $args;
}

#------------------------------------------------------------------------------

sub register {
    my ($self, %args) = @_;

    my $stack = $args{stack};
    my $pin   = $args{pin};
    my $did_register = 0;
    my $errors       = 0;

    for my $pkg ($self->packages) {

      if (my $reg = $pkg->registrations->find( {stack => $stack->id} ) ) {
          $self->debug( sub {"Package $pkg is already on stack $stack"} );
          $reg->pin && $did_register++ if $pin and not $reg->is_pinned;
          next;
      }

      my $incumbent = $stack->registration(package => $pkg->name);

      if (not $incumbent) {
          $self->debug(sub {"Registering $pkg on stack $stack"} );
          $pkg->register(stack => $stack, pin => $pin);
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
      $pkg->register(stack => $stack, pin => $pin);
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

sub registered_stacks {
    my ($self) = @_;

    my %stacks;

    for my $reg ($self->registrations) {
      # TODO: maybe use 'DISTICT'
      $stacks{$reg->stack} = $reg->stack;
    }

    return values %stacks;
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
         'w' => sub { $self->version()                        },
         'm' => sub { $self->is_devel()   ? 'd' : 'r'         },
         'p' => sub { $self->path()                           },
         'P' => sub { $self->native_path()                    },
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

    return '%A/%f',
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------
1;

__END__
