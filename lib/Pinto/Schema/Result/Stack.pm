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

Related object: L<Pinto::Schema::Result::Kommit>

=cut

__PACKAGE__->belongs_to(
  "head",
  "Pinto::Schema::Result::Kommit",
  { id => "head" },
  { is_deferrable => 0, on_delete => "RESTRICT", on_update => "NO ACTION" },
);

=head2 registrations

Type: has_many

Related object: L<Pinto::Schema::Result::Registration>

=cut

__PACKAGE__->has_many(
  "registrations",
  "Pinto::Schema::Result::Registration",
  { "foreign.stack" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head1 L<Moose> ROLES APPLIED

=over 4

=item * L<Pinto::Role::Schema::Result>

=back

=cut


with 'Pinto::Role::Schema::Result';


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-02-21 23:16:38
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:UqRFX6GAcrFZPOUdJm5LfA

#-------------------------------------------------------------------------------

# ABSTRACT: Represents a named set of Packages

#-------------------------------------------------------------------------------

# VERSION

#-------------------------------------------------------------------------------

use MooseX::Types::Moose qw(Bool);

use String::Format;
use File::Copy::Recursive ();
use File::Copy ();

use Pinto::Util qw(itis mksymlink current_time);
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

sub BUILD {
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
            my $entries = $self->registry->lookup(distribution => $spec->path);
            return $entries ? $self->repo->get_distribution(path => $spec->path) : ();
        }
        elsif ( itis($spec, 'Pinto::PackageSpec') ) {
            my $entry = $self->registry->lookup(package => $spec->name);
            return () if !$entry or $entry->version < $spec->version;
            return $self->repo->get_distribution(path => $entry->path);
        }
    }

    throw 'Invalid arguments';
}

#------------------------------------------------------------------------------

sub copy {
    my ($self, %changes) = @_;

    my $copy_name = $changes{name};

    $changes{is_default} = 0; # Never duplicate the default flag

    my $orig_dir = $self->stack_dir;
    throw "Directory $orig_dir does not exist" if not -e $orig_dir;

    my $copy_dir = $self->repo->config->root_dir->subdir($copy_name);
    throw "Directory $copy_dir already exists" if -e $copy_dir;

    $self->debug("Copying directory $orig_dir to $copy_dir");
    File::Copy::Recursive::rcopy($self->stack_dir, $copy_dir)  or throw "Copy failed: $!";

    my $copy = $self->next::method(\%changes);

    return $copy;
}

#------------------------------------------------------------------------------

sub rename {
    my ($self, %args) = @_;

    my $new_name = $args{to};

    $self->assert_not_locked;

    my $orig_dir = $self->stack_dir;
    throw "Directory $orig_dir does not exist" if not -e $orig_dir;

    my $new_dir = $self->repo->config->root_dir->subdir($new_name);
    throw "Directory $new_dir already exists" if -e $new_dir;

    $self->debug("Renaming directory $orig_dir to $new_dir");
    File::Copy::move($orig_dir, $new_dir) or throw "Rename failed: $!";

    $self->update( {name => $new_name} );

    return $self
}

#------------------------------------------------------------------------------

sub kill {
    my ($self) = @_;

    $self->assert_not_locked;

    throw "Cannot kill the default stack" if $self->is_default;

    $self->delete;

    my $stack_dir = $self->stack_dir;
    $stack_dir->rmtree or throw "Failed to remove $stack_dir: $!";

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

sub commit {
    my ($self, %args) = @_;

    my $kommit = $self->schema->create_kommit(\%args);
    $kommit->add_parent(kommit => $self->head);
    $self->update( {head => $kommit} );

    return $self;
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

    return $self->registry->has_changed;
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

    my $r = ($stack_a->head_revision <=> $stack_b->head_revision);

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
           I => sub { $self->head->sha256                                 },
           i => sub { $self->head->sha256_prefix                          },
           G => sub { $self->head->message                                },
           t => sub { $self->head->message_title                          },
           b => sub { $self->head->message_body                           },
           J => sub { $self->head->username                               },
           U => sub { $self->head->timestamp->strftime('%b %e %Y %H:%M')  }, 
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
