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

=head2 name_canonical

  data_type: 'text'
  is_nullable: 0

=head2 description

  data_type: 'text'
  is_nullable: 0

=head2 is_default

  data_type: 'boolean'
  is_nullable: 0

=head2 is_locked

  data_type: 'boolean'
  is_nullable: 0

=head2 last_commit_id

  data_type: 'text'
  default_value: (empty string)
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "name",
  { data_type => "text", is_nullable => 0 },
  "name_canonical",
  { data_type => "text", is_nullable => 0 },
  "description",
  { data_type => "text", is_nullable => 0 },
  "is_default",
  { data_type => "boolean", is_nullable => 0 },
  "is_locked",
  { data_type => "boolean", is_nullable => 0 },
  "last_commit_id",
  { data_type => "text", default_value => "", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<name_canonical_unique>

=over 4

=item * L</name_canonical>

=back

=cut

__PACKAGE__->add_unique_constraint("name_canonical_unique", ["name_canonical"]);

=head2 C<name_unique>

=over 4

=item * L</name>

=back

=cut

__PACKAGE__->add_unique_constraint("name_unique", ["name"]);

=head1 L<Moose> ROLES APPLIED

=over 4

=item * L<Pinto::Role::Schema::Result>

=back

=cut


with 'Pinto::Role::Schema::Result';


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-01-23 13:33:43
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:PUDO12IUL14R7s9N73hFpQ

#-------------------------------------------------------------------------------

# ABSTRACT: Represents a named set of Packages

#-------------------------------------------------------------------------------

# VERSION

#-------------------------------------------------------------------------------

use MooseX::Types::Moose qw(Bool);

use String::Format;
use File::Copy::Recursive ();

use Pinto::Util qw(itis mksymlink current_time);
use Pinto::Types qw(Dir File);
use Pinto::Exception qw(throw);
use Pinto::IndexWriter;
use Pinto::Registry;

use overload ( '""'  => 'to_string',
               '<=>' => 'numeric_compare',
               'cmp' => 'string_compare' );

#------------------------------------------------------------------------------

has stack_dir => (
  is          => 'ro',
  isa         => Dir,
  lazy        => 1,
  default     => sub { $_[0]->repo->root_dir->subdir( $_[0]->name_canonical ) },
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


has work_dir => (
  is          => 'ro',
  isa         => Dir,
  lazy        => 1,
  default     => sub { $_[0]->stack_dir->subdir( 'work' ) },
);


has index_file => (
  is          => 'ro',
  isa         => File,
  lazy        => 1,
  default     => sub { $_[0]->modules_dir->file('02packages.details.txt.gz') },
);


has registry_file => (
  is          => 'ro',
  isa         => File,
  lazy        => 1,
  default     => sub { $_[0]->work_dir->file('stack.registry.txt') },
);


has registry => (
  is       => 'ro',
  isa      => 'Pinto::Registry',
  lazy     => 1,
  handles  => [ qw(lookup register unregister pin unpin) ],
  default  => sub { Pinto::Registry->new( file   => $_[0]->registry_file,
                                          logger => $_[0]->logger,
                                          repo   => $_[0]->repo ) },
);

#------------------------------------------------------------------------------

sub FOREIGNBUILDARGS {
  my ($class, $args) = @_;

  $args ||= {};
  $args->{is_default}  ||= 0;
  $args->{is_locked}   ||= 0;
  $args->{description} ||= '';
  $args->{name_canonical} = lc $args->{name};


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

  my $stack_work_dir = $self->work_dir;
  $stack_work_dir->mkpath;

  return $self;
}

#------------------------------------------------------------------------------

sub copy {
    my ($self, %changes) = @_;

    my $copy_name = $changes{name};
    my $copy_stack_canon = $changes{name_canonical} = lc $copy_name;

    $changes{description} ||= "Copy of stack $self"; 
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
    my $new_name_canon = lc $new_name;

    my $orig_dir = $self->stack_dir;
    throw "Directory $orig_dir does not exist" if not -e $orig_dir;

    my $new_dir = $self->repo->config->root_dir->subdir($new_name_canon);
    throw "Directory $new_dir already exists" if -e $new_dir;

    $self->debug("Renaming directory $orig_dir to $new_dir");
    File::Copy::Recursive::rmove($orig_dir, $new_dir) or throw "Rename failed: $!";

    $self->update( {name => $new_name, name_canonical => $new_name_canon} );

    return $self
}

#------------------------------------------------------------------------------

sub delete {
    my ($self) = @_;

    $self->next::method;

    my $stack_dir = $self->stack_dir;
    $stack_dir->rmtree or throw "Failed to remove $stack_dir: $!";

    return $self;
}

#------------------------------------------------------------------------------

sub lock {
    my ($self) = @_;

    if ($self->is_locked) {
      $self->warning("Stack $self is already locked");
      return $self;
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
      return $self;
    }

    $self->notice("Unlocking stack $self");
    $self->update( {is_locked => 0} );

    return $self;
}

#------------------------------------------------------------------------------

sub check_lock {
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
    # or $self->properties->has_changed;
}

#------------------------------------------------------------------------------

sub has_not_changed {
    my ($self) = @_;

    return ! $self->has_changed;
}

#------------------------------------------------------------------------------

sub last_commit_id_prefix {
  my ($self) = @_;

  return substr $self->last_commit_id, 0, 7;
}

#------------------------------------------------------------------------------

sub write_index {
    my ($self) = @_;

    my $writer = Pinto::IndexWriter->new( file    => $self->index_file,
                                          entries => $self->registry->entries,
                                          logger  => $self->logger );

    $writer->write_index;

    return $self;
}

#------------------------------------------------------------------------------

sub write_registry {
    my ($self) = @_;

    $self->registry->write;

    return $self;
}

#------------------------------------------------------------------------------

sub finalize {
    my ($self) = @_;

    $self->write_index;
    $self->write_registry;

    return $self;
}

#------------------------------------------------------------------------------

sub commit {
    my ($self, %args) = @_;

    return $self->repo->commit(stack => $self, %args);
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
           k => sub { $self->name                                    },
           M => sub { $self->is_default                  ? '*' : ' ' },
           L => sub { $self->is_locked                   ? '!' : ' ' },
           I => sub { $self->last_commit_id                          },
           i => sub { $self->last_commit_id_prefix                   },
           G => sub { $self->last_commit_message                     },
           J => sub { $self->last_committed_by                       },
           U => sub { $self->last_committed_on->strftime('%c')       },
           e => sub { $self->description                             },
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
