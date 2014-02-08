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

=head2 metadata

  data_type: 'text'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
    "id", { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
    "author",   { data_type => "text",    is_nullable => 0 },
    "archive",  { data_type => "text",    is_nullable => 0 },
    "source",   { data_type => "text",    is_nullable => 0 },
    "mtime",    { data_type => "integer", is_nullable => 0 },
    "sha256",   { data_type => "text",    is_nullable => 0 },
    "md5",      { data_type => "text",    is_nullable => 0 },
    "metadata", { data_type => "text",    is_nullable => 0 },
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

__PACKAGE__->add_unique_constraint( "author_archive_unique", [ "author", "archive" ] );

=head1 RELATIONS

=head2 packages

Type: has_many

Related object: L<Pinto::Schema::Result::Package>

=cut

__PACKAGE__->has_many(
    "packages",
    "Pinto::Schema::Result::Package",
    { "foreign.distribution" => "self.id" },
    { cascade_copy           => 0, cascade_delete => 0 },
);

=head2 prerequisites

Type: has_many

Related object: L<Pinto::Schema::Result::Prerequisite>

=cut

__PACKAGE__->has_many(
    "prerequisites",
    "Pinto::Schema::Result::Prerequisite",
    { "foreign.distribution" => "self.id" },
    { cascade_copy           => 0, cascade_delete => 0 },
);

=head2 registrations

Type: has_many

Related object: L<Pinto::Schema::Result::Registration>

=cut

__PACKAGE__->has_many(
    "registrations",
    "Pinto::Schema::Result::Registration",
    { "foreign.distribution" => "self.id" },
    { cascade_copy           => 0, cascade_delete => 0 },
);

=head1 L<Moose> ROLES APPLIED

=over 4

=item * L<Pinto::Role::Schema::Result>

=back

=cut

with 'Pinto::Role::Schema::Result';

# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-03-26 11:05:47
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:vQKIXXk8xddyMmBptwvpUg

#-------------------------------------------------------------------------------

# ABSTRACT: Represents a distribution archive

#-------------------------------------------------------------------------------

use URI;
use CPAN::Meta;
use Path::Class;
use CPAN::DistnameInfo;
use String::Format;

use Pinto::Util qw(itis debug whine throw);
use Pinto::Target::Distribution;

use overload (
    '""'  => 'to_string',
    'cmp' => 'string_compare'
);

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

__PACKAGE__->inflate_column(
    'metadata' => {
        inflate => sub { CPAN::Meta->load_json_string( $_[0] ) },
        deflate => sub { $_[0]->as_string( { version => "2" } ) }
    }
);

#------------------------------------------------------------------------------

sub FOREIGNBUILDARGS {
    my ( $class, $args ) = @_;

    $args ||= {};
    $args->{source} ||= 'LOCAL';

    return $args;
}

#------------------------------------------------------------------------------

sub register {
    my ( $self, %args ) = @_;

    my $stack = $args{stack};
    my $pin   = $args{pin} || 0;

    my $can_intermingle = $stack->repo->config->intermingle;
    my $did_register    = 0;

    $stack->assert_is_open;
    $stack->assert_not_locked;

    # TODO: This process makes a of trips to the database.  You could
    # optimize this by fetching all the incumbents at once, checking
    # for pins, and then bulk-insert the new registrations.

    for my $pkg ($self->packages) {

        if (not $pkg->is_simile) {
            my $file = $pkg->file || '';
            debug( sub {"Package $pkg in file $file is not a simile.  Skipping registration"} );
            next;
        }

        my $where = {package_name => $pkg->name};
        my $incumbent = $stack->head->find_related(registrations => $where);

        if (not defined $incumbent) {
            debug( sub {"Registering package $pkg on stack $stack"} );
            $pkg->register(stack => $stack, pin => $pin);
            $did_register++;
            next;
        }
        elsif (not $can_intermingle) {
            # If the repository prohibits intermingled distributions, we can
            # assume all the apckages in the incumbent are already registered.
            my $dist = $incumbent->distribution;
            if ($dist->id == $self->id and $incumbent->is_pinned == $pin) {
                debug( sub {"Distribution $dist is already fully registered"} );
                last;
            }
        }


        my $incumbent_pkg = $incumbent->package;

        if ( $incumbent_pkg == $pkg ) {
            debug( sub {"Package $pkg is already on stack $stack"} );
            $incumbent->pin && $did_register++ if $pin and not $incumbent->is_pinned;
            next;
        }


        if ( $incumbent->is_pinned ) {
            my $pkg_name = $pkg->name;
            throw "Unable to register distribution $self: package $pkg_name is pinned to $incumbent_pkg";
        }

        whine "Downgrading package $incumbent_pkg to $pkg on stack $stack"
            if $incumbent_pkg > $pkg;

        if ( $can_intermingle ) {
            # If the repository allows intermingled distributions, then
            # remove only the incumbent package from the index.
            $incumbent->delete;
        }
        else {
            # Otherwise, remove all packages in the incumbent
            # distribution from the index.  This is the default.
            $incumbent->distribution->unregister(stack => $stack);
        }

      $pkg->register(stack => $stack, pin => $pin);
      $did_register++;
    }

    $stack->mark_as_changed if $did_register;

    return $did_register;
}

#------------------------------------------------------------------------------

sub unregister {
    my ( $self, %args ) = @_;

    my $stack          = $args{stack};
    my $force          = $args{force};
    my $did_unregister = 0;
    my $conflicts      = 0;

    $stack->assert_is_open;
    $stack->assert_not_locked;

    my $rs = $self->registrations( { revision => $stack->head->id } );
    for my $reg ( $rs->all ) {

        if ( $reg->is_pinned and not $force ) {
            my $pkg = $reg->package;
            whine "Cannot unregister package $pkg because it is pinned to stack $stack";
            $conflicts++;
            next;
        }

        $did_unregister++;
    }

    throw "Unable to unregister distribution $self from stack $stack" if $conflicts;

    $rs->delete;

    $stack->mark_as_changed if $did_unregister;

    return $did_unregister;
}

#------------------------------------------------------------------------------

sub pin {
    my ( $self, %args ) = @_;

    my $stack = $args{stack};
    $stack->assert_not_locked;

    my $rev = $stack->head;
    $rev->assert_is_open;

    my $where = { revision => $rev->id, is_pinned => 0 };
    my $regs = $self->registrations($where);

    return 0 if not $regs->count;

    $regs->update( { is_pinned => 1 } );
    $stack->mark_as_changed;

    return 1;
}

#------------------------------------------------------------------------------

sub unpin {
    my ( $self, %args ) = @_;

    my $stack = $args{stack};
    $stack->assert_not_locked;

    my $rev = $stack->head;
    $rev->assert_is_open;

    my $where = { revision => $rev->id, is_pinned => 1 };
    my $regs = $self->registrations($where);

    return 0 if not $regs->count;

    $regs->update( { is_pinned => 0 } );
    $stack->mark_as_changed;

    return 1;
}

#------------------------------------------------------------------------------

has distname_info => (
    isa      => 'CPAN::DistnameInfo',
    init_arg => undef,
    handles  => {
        name     => 'dist',
        vname    => 'distvname',
        version  => 'version',
        maturity => 'maturity'
    },
    default => sub { CPAN::DistnameInfo->new( $_[0]->path ) },
    lazy    => 1,
);

#------------------------------------------------------------------------------

has is_devel => (
    is       => 'ro',
    isa      => 'Bool',
    init_arg => undef,
    default  => sub { $_[0]->maturity() eq 'developer' },
    lazy     => 1,
);

#------------------------------------------------------------------------------

sub path {
    my ($self) = @_;

    return join '/', ( substr( $self->author, 0, 1 ), substr( $self->author, 0, 2 ), $self->author, $self->archive );
}

#------------------------------------------------------------------------------

sub native_path {
    my ( $self, @base ) = @_;

    @base = ( $self->repo->config->authors_id_dir ) if not @base;

    return Path::Class::file(
        @base,
        substr( $self->author, 0, 1 ),
        substr( $self->author, 0, 2 ),
        $self->author, $self->archive
    );
}

#------------------------------------------------------------------------------

sub uri {
    my ( $self, $base ) = @_;

    # TODO: Is there a sensible URI for local dists?
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
    my ( $self, %args ) = @_;

    my $pkg_name = $args{name};

    my $where = { name => $pkg_name };
    my $attrs = { key  => 'name_distribution_unique' };
    my $pkg = $self->find_related( 'packages', $where, $attrs ) or return;

    if ( my $stk_name = $args{stack} ) {
        return $pkg->registration( stack => $stk_name ) ? $pkg : ();
    }

    return $pkg;
}

#------------------------------------------------------------------------------

sub registered_stacks {
    my ($self) = @_;

    my %stacks;

    for my $reg ( $self->registrations ) {

        # TODO: maybe use 'DISTICT'
        $stacks{ $reg->stack } = $reg->stack;
    }

    return values %stacks;
}

#------------------------------------------------------------------------------

sub main_module {
    my ($self) = @_;

    # We start by sorting packages by the length of their name.  Most of
    # the time, the shorter one is more likely to be the main module name.
    my @pkgs = sort { length $a->name <=> length $b->name } $self->packages;

    # Transform the dist name into a package name
    my $dist_name = $self->name;
    $dist_name =~ s/-/::/g;

    # First, look for an indexable package that matches the dist name
    for my $pkg (@pkgs) {
        return $pkg if $pkg->can_index && $pkg->name eq $dist_name;
    }

    # Then, look for any indexable package
    for my $pkg (@pkgs) {
        return $pkg if $pkg->is_simile;
    }

    # Then, just use the first package
    return $pkgs[0] if @pkgs;

    # There are no packages
    return undef;
}

#------------------------------------------------------------------------------

sub package_count {
    my ($self) = @_;

    return scalar $self->packages;
}

#------------------------------------------------------------------------------

sub prerequisite_specs {
    my ($self) = @_;

    return map { $_->as_target } $self->prerequisites;
}

#------------------------------------------------------------------------------

sub as_target {
    my ($self) = @_;

    return Pinto::Target::Distribution->new( path => $self->path );
}

#------------------------------------------------------------------------------

sub string_compare {
    my ( $dist_a, $dist_b ) = @_;

    my $pkg = __PACKAGE__;
    throw "Can only compare $pkg objects"
        if not( itis( $dist_a, $pkg ) && itis( $dist_b, $pkg ) );

    return 0 if $dist_a->id == $dist_b->id;

    my $r = ( $dist_a->archive cmp $dist_b->archive );

    return $r;
}

#------------------------------------------------------------------------------

sub to_string {
    my ( $self, $format ) = @_;

    my %fspec = (
        'd' => sub { $self->name },
        'D' => sub { $self->vname },
        'V' => sub { $self->version },
        'm' => sub { $self->is_devel ? 'd' : 'r' },
        'M' => sub { my $m = $self->main_module; $m ? $m->name : '' },
        'h' => sub { $self->path },
        'H' => sub { $self->native_path },
        'f' => sub { $self->archive },
        's' => sub { $self->is_local ? 'l' : 'f' },
        'S' => sub { $self->source },
        'a' => sub { $self->author },
        'u' => sub { $self->uri },
        'c' => sub { $self->package_count },
    );

    $format ||= $self->default_format;
    return String::Format::stringf( $format, %fspec );
}

#-------------------------------------------------------------------------------

sub default_format {
    my ($self) = @_;

    return '%a/%f',    # AUTHOR/Dist-Name-1.0.tar.gz
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------
1;

__END__
