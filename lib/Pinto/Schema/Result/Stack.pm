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
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "name",
  { data_type => "text", is_nullable => 0 },
  "is_default",
  { data_type => "boolean", is_nullable => 0 },
  "is_locked",
  { data_type => "boolean", is_nullable => 0 },
  "properties",
  { data_type => "text", is_nullable => 0 },
  "head",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
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

__PACKAGE__->add_unique_constraint("name_unique", ["name"]);

=head1 RELATIONS

=head2 head

Type: belongs_to

Related object: L<Pinto::Schema::Result::Revision>

=cut

__PACKAGE__->belongs_to(
  "head",
  "Pinto::Schema::Result::Revision",
  { id => "head" },
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

use MooseX::Types::Moose qw(Bool);

use String::Format;
use File::Copy ();

use Pinto::Util qw(itis mksymlink);
use Pinto::Types qw(Dir File);
use Pinto::Exception qw(throw);
use Pinto::IndexWriter;

use overload ( '""'  => 'to_string',
               '<=>' => 'numeric_compare',
               'cmp' => 'string_compare' );

#------------------------------------------------------------------------------

has stack_dir => (
  is          => 'ro',
  isa         => Dir,
  lazy        => 1,
  default     => sub { $_[0]->repo->root_dir->subdir( $_[0]->name ) },
);


has modules_dir => (
  is          => 'ro',
  isa         => Dir,
  lazy        => 1,
  default     => sub { $_[0]->stack_dir->subdir( 'modules' ) },
);


has authors_dir => (
  is          => 'ro',
  isa         => Dir,
  lazy        => 1,
  default     => sub { $_[0]->stack_dir->subdir( 'authors' ) },
);


has index_file => (
  is          => 'ro',
  isa         => File,
  lazy        => 1,
  default     => sub { $_[0]->modules_dir->file('02packages.details.txt.gz') },
);

#------------------------------------------------------------------------------

sub FOREIGNBUILDARGS {
  my ($class, $args) = @_;

  $args ||= {};
  $args->{is_default}  ||= 0;
  $args->{is_locked}   ||= 0;
  $args->{properties}  ||= '{}';

  return $args;
}

#------------------------------------------------------------------------------

before is_default => sub {
  my ($self, @args) = @_;
  throw "Cannot directly set is_default.  Use mark_as_default instead" if @args;
};


#------------------------------------------------------------------------------

=method get_distribution( spec => $dist_spec )

Given a L<Pinto::PackageSpec>, returns the L<Pinto::Schema::Result::Distribution>
which contains the package with the same name as the spec B<and the same or higher 
version as the spec>.  Returns nothing if no such distribution is found in 
this stack.

=method get_distribution( spec => $pkg_spec )

Given a L<Pinto::DistributionSpec>, returns the L<Pinto::Schema::Result::Distribution>
from this stack with the same author id and archive attributes as the spec.  
Returns nothing if no such distribution is found in this stack.

=cut

sub get_distribution {
    my ($self, %args) = @_;

    if (my $spec = $args{spec}) {
        if ( itis($spec, 'Pinto::DistributionSpec') ) {

            my $attrs = {prefetch => [ qw(distribution) ], distinct => 1};
            my $where = {'distribution.author'  => $spec->author, 
                         'distribution.archive' => $spec->archive};

            my $reg = $self->head->search_related(registrations => $where, $attrs)->first;
            return if not defined $reg;

            return $reg->distribution;
        }
        elsif ( itis($spec, 'Pinto::PackageSpec') ) {

            my $attrs = {prefetch => [ qw(package distribution) ] };
            my $where = {package_name => $spec->name};

            my $reg = $self->head->find_related(registrations => $where, $attrs);
            return if not defined $reg;

            return if $reg->package->version < $spec->version;
            return $reg->distribution;
        }
    }

    throw 'Invalid arguments';
}

#------------------------------------------------------------------------------

sub make_filesystem {
    my ($self) = @_;

    my $stack_dir = $self->stack_dir;
    $stack_dir->mkpath;

    my $stack_modules_dir = $self->modules_dir;
    $stack_modules_dir->mkpath;

    my $stack_authors_dir  = $self->authors_dir;
    my $shared_authors_dir = $self->repo->config->authors_dir->relative($stack_dir);
    mksymlink($stack_authors_dir => $shared_authors_dir);

    my $stack_modlist_file  = $stack_modules_dir->file('03modlist.data.gz');
    my $shared_modlist_file = $self->repo->config->modlist_file->relative($stack_modules_dir);
    mksymlink($stack_modlist_file => $shared_modlist_file);

  return $self;
}

#------------------------------------------------------------------------------

sub rename_filesystem {
    my ($self, %args) = @_;

    my $new_name = $args{to};

    $self->assert_not_locked;

    my $orig_dir = $self->stack_dir;
    throw "Directory $orig_dir does not exist" if not -e $orig_dir;

    my $new_dir = $self->repo->config->root_dir->subdir($new_name);
    throw "Directory $new_dir already exists" if -e $new_dir;

    $self->debug("Renaming directory $orig_dir to $new_dir");
    File::Copy::move($orig_dir, $new_dir) or throw "Rename failed: $!";

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
    my ($self, %changes) = @_;

    $changes{is_default} = 0; # Never duplicate the default flag

    return $self->copy(\%changes);
}

#------------------------------------------------------------------------------

sub duplicate_registrations {
    my ($self, %args) = @_;

    my $rev = $args{to};
    $self->info("Copying registrations for stack $self to $rev");

    my $where = {revision => $self->head->id};
    my $attrs = {result_class => 'DBIx::Class::ResultClass::HashRefInflator'};
    my $rs = $self->result_source->schema->resultset('Registration');

    my @rows = $rs->search($where, $attrs)->all;
    for (@rows) { delete $_->{id}; $_->{revision} = $rev->id; } 

    $rs->populate(\@rows);

    return $self;
}

#------------------------------------------------------------------------------

sub move_registrations {
    my ($self, %args) = @_;

    my $rev = $args{to};
    $self->info("Moving registrations for stack $self to $rev");

    my $rs = $self->head->registrations;
    $rs->update({revision => $rev->id});

    return $self;
}

#------------------------------------------------------------------------------

sub rename {
    my ($self, %args) = @_;

    my $new_name = $args{to};

    $self->assert_not_locked;

    $self->update( {name => $new_name} );

    return $self
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

    if ($self->is_locked) {
      $self->warning("Stack $self is already locked");
      return 0;
    }

    $self->notice("Locking stack $self");
    $self->update( {is_locked => 1} );
    return 1;
}

#------------------------------------------------------------------------------

sub unlock {
    my ($self) = @_;

    if (not $self->is_locked) {
      $self->warning("Stack $self is not locked");
      return 0;
    }

    $self->notice("Unlocking stack $self");
    $self->update( {is_locked => 0} );

    return 1;
}

#------------------------------------------------------------------------------

sub set_head {
    my ($self, $revision) = @_;

    $self->update( {head => $revision} );

    return $self;
}

#------------------------------------------------------------------------------

sub start_revision {
    my ($self) = @_;

    $self->assert_is_committed;

    my $old_rev  = $self->head;
    my $new_rev  = $self->result_source->schema->create_revision( {} );

    my $method = ($self->should_keep_history ? 'duplicate' : 'move') . '_registrations';
    $self->$method(to => $new_rev);

    $new_rev->add_parent($old_rev);
    $self->set_head($new_rev);
    
    $self->assert_is_open;

    return $self;
}

#------------------------------------------------------------------------------

sub commit_revision {
    my ($self, %args) = @_;

    throw "Must specify a message to commit" 
      if not ($args{message} or $self->head->message);

    $self->assert_is_open;

    $self->head->commit(%args);
    $self->write_index;

    $self->assert_is_committed;

    return $self;
}

#-------------------------------------------------------------------------------

sub should_keep_history {
  my ($self) = @_;

  # Is this repo configured to keep history?
  return 1 if not $self->repo->config->nohistory;

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

    my $attrs = {select => 'distribution', distinct => 1};
    return $self->head->registrations({}, $attrs)->count;
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

sub assert_not_locked {
    my ($self) = @_;

    throw "Stack $self is locked and cannot be modified or deleted" 
      if $self->is_locked;

    return $self;
}

#------------------------------------------------------------------------------

sub mark_as_default {
    my ($self) = @_;

    if ($self->is_default) {
        $self->warning("Stack $self is already the default");
        return 0;
    }

    $self->debug('Marking all stacks as non-default');
    my $rs = $self->result_source->resultset->search;
    $rs->update_all( {is_default => 0} );

    $self->notice("Marking stack $self as default");
    $self->update( {is_default => 1} );

    return 1;
}

#------------------------------------------------------------------------------

sub unmark_as_default {
    my ($self) = @_;

    if (not $self->is_default) {
        $self->warning("Stack $self is not the default");
        return 0;
    }

    $self->notice("Un marking stack $self as default");
    $self->update( {is_default => 0} );

    return 1;
}

#------------------------------------------------------------------------------

sub has_changed {
    my ($self) = @_;

    return 1;
}

#------------------------------------------------------------------------------

sub has_not_changed {
    my ($self) = @_;

    return ! $self->has_changed;
}

#------------------------------------------------------------------------------

sub write_index {
    my ($self) = @_;

    my $writer = Pinto::IndexWriter->new( stack  => $self,
                                          logger => $self->repo->logger,
                                          config => $self->repo->config );
    $writer->write_index;

    return $self;
}

#------------------------------------------------------------------------------

sub numeric_compare {
    my ($stack_a, $stack_b) = @_;

    my $pkg = __PACKAGE__;
    throw "Can only compare $pkg objects"
        if not ( itis($stack_a, $pkg) && itis($stack_b, $pkg) );

    return 0 if $stack_a->id == $stack_b->id;

    my $r = ($stack_a->head <=> $stack_b->head);

    return $r;
}

#------------------------------------------------------------------------------

sub string_compare {
    my ($stack_a, $stack_b) = @_;

    my $pkg = __PACKAGE__;
    throw "Can only compare $pkg objects"
        if not ( itis($stack_a, $pkg) && itis($stack_b, $pkg) );

    return 0 if $stack_a->id == $stack_b->id;

    my $r =   ($stack_a->name cmp $stack_b->name);

    return $r;
}

#------------------------------------------------------------------------------

sub to_string {
    my ($self, $format) = @_;

    my %fspec = (
           k => sub { $self->name                                         },
           M => sub { $self->is_default                       ? '*' : ' ' },
           L => sub { $self->is_locked                        ? '!' : ' ' },
           I => sub { $self->head->uuid                                   },
           i => sub { $self->head->uuid_prefix                            },
           G => sub { $self->head->message                                },
           t => sub { $self->head->message_title                          },
           b => sub { $self->head->message_body                           },
           j => sub { $self->head->username                               },
           u => sub { $self->head->datetime->strftime('%c')               }, 
    );

    $format ||= $self->default_format();
    return String::Format::stringf($format, %fspec);
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