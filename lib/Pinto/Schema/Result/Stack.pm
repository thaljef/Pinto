use utf8;

package Pinto::Schema::Result::Stack;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Pinto::Schema::Result::Stack

=cut

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

=head1 TABLE: C<stack>

=cut

__PACKAGE__->table("stack");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 name

  data_type: 'text'
  is_nullable: 0

=head2 is_default

  data_type: 'boolean'
  is_nullable: 0

=head2 is_locked

  data_type: 'boolean'
  is_nullable: 0

=head2 properties

  data_type: 'text'
  is_nullable: 0

=head2 head

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
    "id", { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
    "name",       { data_type => "text",    is_nullable    => 0 },
    "is_default", { data_type => "boolean", is_nullable    => 0 },
    "is_locked",  { data_type => "boolean", is_nullable    => 0 },
    "properties", { data_type => "text",    is_nullable    => 0 },
    "head",       { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<name_unique>

=over 4

=item * L</name>

=back

=cut

__PACKAGE__->add_unique_constraint( "name_unique", ["name"] );

=head1 RELATIONS

=head2 head

Type: belongs_to

Related object: L<Pinto::Schema::Result::Revision>

=cut

__PACKAGE__->belongs_to(
    "head",
    "Pinto::Schema::Result::Revision",
    { id            => "head" },
    { is_deferrable => 0, on_delete => "RESTRICT", on_update => "NO ACTION" },
);

=head1 L<Moose> ROLES APPLIED

=over 4

=item * L<Pinto::Role::Schema::Result>

=back

=cut

with 'Pinto::Role::Schema::Result';

# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-03-04 12:39:54
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:+O/IwTdVRx98MHUkJ281lg

#-------------------------------------------------------------------------------

# ABSTRACT: Represents a named set of Packages

#-------------------------------------------------------------------------------

# VERSION

#-------------------------------------------------------------------------------

use MooseX::Types::Moose qw(Bool Str Undef);

use String::Format;
use File::Copy ();
use JSON qw(encode_json decode_json);

use Pinto::Util qw(:all);
use Pinto::Types qw(Dir File Version);

use version;
use overload (
    '""'  => 'to_string',
    '<=>' => 'numeric_compare',
    'cmp' => 'string_compare'
);

#------------------------------------------------------------------------------

__PACKAGE__->inflate_column(
    'properties' => {
        inflate => sub { decode_json( $_[0] || '{}' ) },
        deflate => sub { encode_json( $_[0] || {} ) }
    }
);

#------------------------------------------------------------------------------

has stack_dir => (
    is      => 'ro',
    isa     => Dir,
    lazy    => 1,
    default => sub { $_[0]->repo->config->stacks_dir->subdir( $_[0]->name ) },
);

has modules_dir => (
    is      => 'ro',
    isa     => Dir,
    lazy    => 1,
    default => sub { $_[0]->stack_dir->subdir('modules') },
);

has authors_dir => (
    is      => 'ro',
    isa     => Dir,
    lazy    => 1,
    default => sub { $_[0]->stack_dir->subdir('authors') },
);

has description => (
    is       => 'ro',
    isa      => Str | Undef,
    lazy     => 1,
    default  => sub { $_[0]->get_property('description') },
    init_arg => undef,
);

has target_perl_version => (
    is      => 'ro',
    isa     => Version,
    lazy    => 1,
    default => sub {
        $_[0]->get_property('target_perl_version')
            or $_[0]->repo->config->target_perl_version;
    },
    init_arg => undef,
    coerce   => 1,
);

#------------------------------------------------------------------------------

sub FOREIGNBUILDARGS {
    my ( $class, $args ) = @_;

    $args               ||= {};
    $args->{is_default} ||= 0;
    $args->{is_locked}  ||= 0;
    $args->{properties} ||= '{}';

    return $args;
}

#------------------------------------------------------------------------------

before is_default => sub {
    my ( $self, @args ) = @_;
    throw "Cannot directly set is_default.  Use mark_as_default instead" if @args;
};

#------------------------------------------------------------------------------
# TODO: All methods below that operate on the head should be moved into the
# Revision class, since that is where the data actually is.  For convenience,
# the Stack class can have the same methods, but they should just delegate to
# the Revision class.
#------------------------------------------------------------------------------

=method get_distribution( target => $target )

Given a L<Pinto::Target::Package>, returns the L<Pinto::Schema::Result::Distribution>
which contains the package with the same name as the target B<and the same or higher 
version as the target>.  Returns nothing if no such distribution is found in 
this stack.

Given a L<Pinto::Target::Distribution>, returns the L<Pinto::Schema::Result::Distribution>
from this stack with the same author id and archive attributes as the target.  
Returns nothing if no such distribution is found in this stack.

You can also pass a C<cache> argument that must be a reference to a hash.  It will
be used to cache results so that repeated calls to C<get_distribution> require
fewer trips to the database.  It is up to you to decide when to expire the cache.

=cut

sub get_distribution {
    my ( $self, %args ) = @_;

    my $cache  = $args{cache};
    my $target = $args{target} or throw 'Invalid arguments';
    return $cache->{$target} if $cache && exists $cache->{$target};

    my $dist;
    if ( itis( $target, 'Pinto::Target::Distribution' ) ) {

        my $attrs = { prefetch => 'distribution'};
        my $where = {'distribution.author'  => $target->author, 'distribution.archive' => $target->archive};

        return unless my $reg = $self->head->search_related( registrations => $where, $attrs )->first;
        $dist = $reg->distribution;
    }
    elsif ( itis( $target, 'Pinto::Target::Package' ) ) {

        my $attrs = { prefetch     => 'distribution' };
        my $where = { package_name => $target->name  };

        return unless my $reg = $self->head->find_related( registrations => $where, $attrs );
        return unless $target->is_satisfied_by($reg->package->version);
        $dist = $reg->distribution;
    }

    $cache->{$target} = $dist if $cache;
    return $dist;
}

#------------------------------------------------------------------------------

sub make_filesystem {
    my ($self) = @_;

    my $stack_dir = $self->stack_dir;
    debug "Making stack directory at $stack_dir";
    $stack_dir->mkpath;

    my $stack_modules_dir = $self->modules_dir;
    debug "Making modules directory at $stack_modules_dir";
    $stack_modules_dir->mkpath;

    my $stack_authors_dir  = $self->authors_dir;
    my $shared_authors_dir = $self->repo->config->authors_dir->relative($stack_dir);
    mksymlink( $stack_authors_dir => $shared_authors_dir );

    $self->write_modlist;

    return $self;
}

#------------------------------------------------------------------------------

sub rename_filesystem {
    my ( $self, %args ) = @_;

    my $new_name = $args{to};

    $self->assert_not_locked;

    my $orig_dir = $self->stack_dir;
    throw "Directory $orig_dir does not exist" 
        if not -e $orig_dir;

    my $new_dir = $self->repo->config->stacks_dir->subdir($new_name);
    throw "Directory $new_dir already exists" 
        if -e $new_dir && (lc $new_dir ne lc $orig_dir);

    debug "Renaming directory $orig_dir to $new_dir";
    File::Copy::move( $orig_dir, $new_dir ) or throw "Rename failed: $!";

    return $self;
}

#------------------------------------------------------------------------------

sub kill_filesystem {
    my ($self) = @_;

    $self->assert_not_locked;

    my $stack_dir = $self->stack_dir;
    $stack_dir->rmtree or throw "Failed to remove $stack_dir: $!";

    return $self;
}

#------------------------------------------------------------------------------

sub duplicate {
    my ( $self, %changes ) = @_;

    $changes{is_default} = 0;    # Never duplicate the default flag

    return $self->copy( \%changes );
}

#------------------------------------------------------------------------------

sub duplicate_registrations {
    my ( $self, %args ) = @_;

    my $new_rev = $args{to};
    my $old_rev = $args{from} || $self->head;

    my $new_rev_id = $new_rev->id;
    my $old_rev_id = $old_rev->id;

    debug "Copying registrations for stack $self to $new_rev";

    # This raw SQL is an optimization.  I was using DBIC's HashReinflator
    # to fetch all the registrations, change the revision, and then reinsert
    # them as new records using populate().  But that was too slow if there
    # are lots of registrations.

    my $sql = qq{
      INSERT INTO registration(revision, package, package_name, distribution, is_pinned)
      SELECT '$new_rev_id', package, package_name, distribution, is_pinned
      FROM registration WHERE revision = '$old_rev_id';
    };

    $self->result_source->storage->dbh->do($sql);

    return $self;
}

#------------------------------------------------------------------------------

sub rename {
    my ( $self, %args ) = @_;

    my $new_name = $args{to};

    $self->assert_not_locked;

    $self->update( { name => $new_name } );

    $self->refresh;    # Causes moose attributes to be reinitialized

    $self->repo->link_modules_dir( to => $self->modules_dir ) if $self->is_default;

    return $self;
}

#------------------------------------------------------------------------------

sub kill {
    my ($self) = @_;

    $self->assert_not_locked;

    throw "Cannot kill the default stack" if $self->is_default;

    $self->delete;

    return $self;
}

#------------------------------------------------------------------------------

sub lock {
    my ($self) = @_;

    return $self if $self->is_locked;

    debug "Locking stack $self";

    $self->update( { is_locked => 1 } );

    return $self;
}

#------------------------------------------------------------------------------

sub unlock {
    my ($self) = @_;

    return $self if not $self->is_locked;

    debug "Unlocking stack $self";

    $self->update( { is_locked => 0 } );

    return $self;
}

#------------------------------------------------------------------------------

sub set_head {
    my ( $self, $revision ) = @_;

    debug sub {"Setting head of stack $self to revision $revision"};

    $self->update( { head => $revision } );

    return $self;
}

#------------------------------------------------------------------------------

sub start_revision {
    my ($self) = @_;

    debug "Starting revision on stack $self";

    $self->assert_is_committed;

    my $old_head = $self->head;
    my $new_head = $self->result_source->schema->create_revision( {} );

    $self->duplicate_registrations( to => $new_head );

    $new_head->add_parent($old_head);
    $self->set_head($new_head);

    $self->assert_is_open;

    return $self;
}

#------------------------------------------------------------------------------

sub commit_revision {
    my ( $self, %args ) = @_;

    throw "Must specify a message to commit"
        if not( $args{message} or $self->head->message );

    $self->assert_is_open;
    $self->assert_has_changed;

    $self->head->commit(%args);
    $self->write_index;

    $self->assert_is_committed;

    return $self;
}

#-------------------------------------------------------------------------------

sub should_keep_history {
    my ($self) = @_;

    # Is this revision referenced by other stacks?
    return 1 if $self->head->stacks->count > 1;

    # Then do not keep history
    return 0;
}

#-------------------------------------------------------------------------------

sub package_count {
    my ($self) = @_;

    return $self->head->registrations->count;
}

#-------------------------------------------------------------------------------

sub distribution_count {
    my ($self) = @_;

    my $attrs = { select => 'distribution', distinct => 1 };
    return $self->head->registrations( {}, $attrs )->count;
}

#------------------------------------------------------------------------------

sub assert_is_open {
    my ($self) = @_;

    return $self->head->assert_is_open;
}

#------------------------------------------------------------------------------

sub assert_is_committed {
    my ($self) = @_;

    return $self->head->assert_is_committed;
}

#------------------------------------------------------------------------------

sub assert_has_changed {
    my ($self) = @_;

    return $self->head->assert_has_changed;
}

#------------------------------------------------------------------------------

sub assert_not_locked {
    my ($self) = @_;

    throw "Stack $self is locked and cannot be modified or deleted"
        if $self->is_locked;

    return $self;
}

#------------------------------------------------------------------------------

sub set_description {
    my ( $self, $description ) = @_;

    $self->set_property( description => $description );

    return $self;
}

#------------------------------------------------------------------------------

sub diff {
    my ( $self, $other ) = @_;

    my $left = $other || ( $self->head->parents )[0];
    my $right = $self;

    require Pinto::Difference;
    return Pinto::Difference->new( left => $left, right => $right );
}

#-----------------------------------------------------------------------------

sub distributions {
    my ($self) = @_;

    return $self->head->distributions;
}

#-----------------------------------------------------------------------------

sub packages {
    my ($self) = @_;

    return $self->head->packages;
}

#-----------------------------------------------------------------------------

sub roots {
    my ($self) = @_;

    my @dists = $self->distributions->all;
    my $tpv   = $self->target_perl_version;
    my %is_prereq_dist;
    my %cache;

    # Algorithm: Visit each distribution and resolve each of its
    # dependencies to the prerequisite distribution (if it exists).
    # Any distribution that is a prerequisite cannot be a root.

    for my $dist ( @dists ) {
        for my $prereq ($dist->prerequisites) {
            # TODO: Decide what to do about development prereqs
            next if $prereq->is_core(in => $tpv) or $prereq->is_perl;
            my %args = (target => $prereq->as_target, cache => \%cache);
            next unless my $prereq_dist = $self->get_distribution(%args);
            $is_prereq_dist{$prereq_dist} = 1;
        }
    }

    return grep { not $is_prereq_dist{$_} } @dists;
}

#-----------------------------------------------------------------------------

sub mark_as_default {
    my ($self) = @_;

    return $self if $self->is_default;

    debug 'Marking all stacks as non-default';
    my $rs = $self->result_source->resultset->search;
    $rs->update_all( { is_default => 0 } );

    debug "Marking stack $self as default";
    $self->update( { is_default => 1 } );

    $self->repo->link_modules_dir( to => $self->modules_dir );

    return 1;
}

#------------------------------------------------------------------------------

sub unmark_as_default {
    my ($self) = @_;

    return $self if not $self->is_default;

    debug "Unmarking stack $self as default";

    $self->update( { is_default => 0 } );

    $self->repo->unlink_modules_dir;

    return 1;
}

#------------------------------------------------------------------------------

sub mark_as_changed {
    my ($self) = @_;

    debug "Marking stack $self as changed";

    $self->head->update( { has_changes => 1 } );

    return $self;
}

#------------------------------------------------------------------------------

sub has_changed {
    my ($self) = @_;

    return $self->head->refresh->has_changes;
}

#------------------------------------------------------------------------------

sub has_not_changed {
    my ($self) = @_;

    return !$self->has_changed;
}

#------------------------------------------------------------------------------

sub write_index {
    my ($self) = @_;

    require Pinto::IndexWriter;
    my $writer = Pinto::IndexWriter->new( stack => $self );
    $writer->write_index;

    return $self;
}

#------------------------------------------------------------------------------

sub write_modlist {
    my ($self) = @_;

    require Pinto::ModlistWriter;
    my $writer = Pinto::ModlistWriter->new( stack => $self );
    $writer->write_modlist;

    return $self;
}

#------------------------------------------------------------------------------

sub get_property {
    my ( $self, @prop_keys ) = @_;

    my %props = %{ $self->get_properties };

    return @props{ map {lc} @prop_keys };
}

#-------------------------------------------------------------------------------

sub get_properties {
    my ($self) = @_;

    my %props = %{ $self->properties };    # Making a copy!

    return \%props;
}

#-------------------------------------------------------------------------------

sub set_property {
    my ( $self, $key, $value ) = @_;

    $self->set_properties( { $key => "$value" } );

    return $self;
}

#-------------------------------------------------------------------------------

sub set_properties {
    my ( $self, $new_props ) = @_;

    my $props = $self->properties;
    while ( my ( $key, $value ) = each %{$new_props} ) {
        Pinto::Util::validate_property_name($key);

        if ( defined $value && length "$value" ) {
            $props->{ lc $key } = "$value";
        }
        else {
            delete $props->{ lc $key };
        }
    }

    $self->update( { properties => $props } );

    return $self;
}

#-------------------------------------------------------------------------------

sub delete_property {
    my ( $self, @prop_keys ) = @_;

    my $props = $self->properties;
    delete $props->{ lc $_ } for @prop_keys;

    $self->update( { properties => $props } );

    return $self;
}

#-------------------------------------------------------------------------------

sub delete_properties {
    my ($self) = @_;

    self->update( { properties => {} } );

    return $self;
}

#-------------------------------------------------------------------------------

sub default_properties {
    my ($self) = @_;

    my $desc = sprintf( 'The %s stack', $self->name );
    my $tpv = $self->repo->config->target_perl_version->stringify;

    return {
        description         => $desc,
        target_perl_version => $tpv
    };
}

#-----------------------------------------------------------------------------

sub numeric_compare {
    my ( $stack_a, $stack_b ) = @_;

    my $pkg = __PACKAGE__;
    throw "Can only compare $pkg objects"
        if not( itis( $stack_a, $pkg ) && itis( $stack_b, $pkg ) );

    return 0 if $stack_a->id == $stack_b->id;

    my $r = ( $stack_a->head <=> $stack_b->head );

    return $r;
}

#-----------------------------------------------------------------------------

sub string_compare {
    my ( $stack_a, $stack_b ) = @_;

    my $pkg = __PACKAGE__;
    throw "Can only compare $pkg objects"
        if not( itis( $stack_a, $pkg ) && itis( $stack_b, $pkg ) );

    return 0 if $stack_a->id == $stack_b->id;

    my $r = ( $stack_a->name cmp $stack_b->name );

    return $r;
}

#------------------------------------------------------------------------------

sub to_string {
    my ( $self, $format ) = @_;

    my %fspec = (
        k => sub { $self->name },
        M => sub { $self->is_default ? '*' : ' ' },
        L => sub { $self->is_locked ? '!' : ' ' },
        I => sub { $self->head->uuid },
        i => sub { $self->head->uuid_prefix },
        g => sub { $self->head->message },
        G => sub { indent_text( trim_text( $self->head->message ), $_[0] ) },
        t => sub { $self->head->message_title },
        T => sub { truncate_text( $self->head->message_title,      $_[0] ) },
        b => sub { $self->head->message_body },
        j => sub { $self->head->username },
        u => sub { $self->head->datetime_local->strftime( $_[0] || '%c' ) },
    );

    $format ||= $self->default_format();
    return String::Format::stringf( $format, %fspec );
}

#-------------------------------------------------------------------------------

sub default_format {
    my ($self) = @_;

    return '%k';
}

#-------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#-------------------------------------------------------------------------------
1;

__END__
