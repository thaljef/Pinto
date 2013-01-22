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

=head2 last_commit_message

  data_type: 'text'
  default_value: (empty string)
  is_nullable: 1

=head2 last_committed_by

  data_type: 'text'
  default_value: (empty string)
  is_nullable: 1

=head2 last_committed_on

  data_type: 'integer'
  default_value: 0
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "name",
  { data_type => "text", is_nullable => 0 },
  "name_canonical",
  { data_type => "text", is_nullable => 0 },
  "is_default",
  { data_type => "boolean", is_nullable => 0 },
  "is_locked",
  { data_type => "boolean", is_nullable => 0 },
  "last_commit_id",
  { data_type => "text", default_value => "", is_nullable => 1 },
  "last_commit_message",
  { data_type => "text", default_value => "", is_nullable => 1 },
  "last_committed_by",
  { data_type => "text", default_value => "", is_nullable => 1 },
  "last_committed_on",
  { data_type => "integer", default_value => 0, is_nullable => 1 },
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


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-01-22 12:32:37
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:3jX/WzKf5XGRwMMNtAGaFA

#-------------------------------------------------------------------------------

# ABSTRACT: Represents a named set of Packages

#-------------------------------------------------------------------------------

# VERSION

#-------------------------------------------------------------------------------


use MooseX::Types::Moose qw(Bool);

use String::Format;
use File::Copy ();
use JSON qw(encode_json decode_json);

use Pinto::Util qw(itis mksymlink current_time);
use Pinto::Types qw(Dir File);
use Pinto::Exception qw(throw);
use Pinto::StackIndex;
use Pinto::StackProps;

use overload ( '""'  => 'to_string',
               '<=>' => 'numeric_compare',
               'cmp' => 'string_compare' );

#------------------------------------------------------------------------------

has stack_dir => (
  is          => 'ro',
  isa         => Dir,
  default     => sub { $_[0]->repo->root_dir->subdir( $_[0]->name ) },
  init_arg    => undef,
  lazy        => 1,
);


has modules_dir => (
  is          => 'ro',
  isa         => Dir,
  default     => sub { $_[0]->stack_dir->subdir( 'modules' ) },
  init_arg    => undef,
  lazy        => 1,
);


has authors_dir => (
  is          => 'ro',
  isa         => Dir,
  default     => sub { $_[0]->stack_dir->subdir( 'authors' ) },
  init_arg    => undef,
  lazy        => 1,
);

has index_file => (
  is          => 'ro',
  isa         => File,
  default     => sub { $_[0]->stack_dir->file('stack.index.txt') },
  init_arg    => undef,
  lazy        => 1,
);


has props_file => (
  is          => 'ro',
  isa         => File,
  default     => sub { $_[0]->stack_dir->file('stack.props.txt') },
  init_arg    => undef,
  lazy        => 1,
);


has index => (
  is       => 'ro',
  isa      => 'Pinto::StackIndex',
  default  => sub { Pinto::StackIndex->new(file => $_[0]->index_file) },
  lazy     => 1,
);


has props => (
  is       => 'ro',
  isa      => 'Pinto::StackProps',
  default  => sub { Pinto::StackProps->new(file => $_[0]->props_file) },
  lazy     => 1,
);

#------------------------------------------------------------------------------

sub FOREIGNBUILDARGS {
  my ($class, $args) = @_;

  $args ||= {};
  $args->{is_default} ||= 0;
  $args->{is_locked}  ||= 0;
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
  my $shared_authors_dir = $self->config->authors_dir->relative($stack_dir);
  mksymlink($stack_authors_dir => $shared_authors_dir);

  my $stack_modlist_file  = $stack_modules_dir->file('03modlist.data.gz');
  my $shared_modlist_file = $self->config->modlist_file->relative($stack_modules_dir);
  mksymlink($stack_modlist_file => $shared_modlist_file);
}

#------------------------------------------------------------------------------

sub open {
    my ($self) = @_;

    $self->check_lock;
    $self->repo->vcs->checkout($self->name);

    return $self;
}

#------------------------------------------------------------------------------

sub close {
    my ($self, %args) = @_;

    $self->index->write;
    my $index_file_basename = $self->index_file->basename;
    my $vcs_index_file = $self->repo->config->vcs_dir->file($index_file_basename);
    File::Copy::copy($self->index_file, $vcs_index_file); # TODO: die!
    $self->repo->vcs->add($index_file_basename);

    $self->props->write;
    my $props_file_basename = $self->props_file->basename;
    my $vcs_props_file = $self->repo->config->vcs_dir->file($props_file_basename);
    File::Copy::copy($self->props_file, $vcs_props_file); # TODO: die!
    $self->repo->vcs->add($props_file_basename);

    my $commit_id = $self->repo->vcs->commit( %args );

    $self->update( { last_commit_id      => $commit_id,
                     last_commit_message => $args{message},
                     last_committed_by   => $args{username},
                     last_committed_on   => current_time });

    return $self;
}

#------------------------------------------------------------------------------

sub copy {
    my ($self, $changes) = @_;

    my $new_stack = $changes->{name};
    my $new_stack_canon = $changes->{name_canonical} = lc $new_stack;

    throw "Stack $new_stack already exists"
      if $self->result_source->resultset->find( {name_canonical => $new_stack_canon} );

    $changes->{is_default} = 0; # Never duplicate the default flag

    return $self->next::method($changes);
}

#------------------------------------------------------------------------------

sub delete {
    my ($self) = @_;

    $self->check_lock;
    $self->stack_dir->rmtree or throw $!;
    $self->repo->vcs->delete_branch(branch => $self->name);

    return $self->next::method;
}

#------------------------------------------------------------------------------

sub rename {
    my ($self, $new_name) = @_;

    my $new_name_canon = lc $new_name;

    throw "Source and destination stacks are the same"
      if $self->name_canonical eq $new_name_canon;

    throw "Stack $new_name already exists"
      if $self->result_source->resultset->find( {name_canonical => $new_name_canon} );

    my $changes = {name => $new_name, name_canonical => $new_name_canon};

    return $self->update($changes);
}

#------------------------------------------------------------------------------

sub get_property {
    my ($self, @prop_keys) = @_;

    my %props = %{ $self->get_properties };

    return @props{ map {lc} @prop_keys };
}

#-------------------------------------------------------------------------------

sub get_properties {
    my ($self) = @_;

    my %props = %{ $self->properties };  # Making a copy!

    return \%props;
}

#-------------------------------------------------------------------------------

sub set_property {
    my ($self, $key, $value) = @_;

    $self->set_properties( {$key => $value} );

    return $self;
}

#-------------------------------------------------------------------------------

sub set_properties {
    my ($self, $new_props) = @_;

    my $props = {}; #$self->properties;
    while (my ($key, $value) = each %{$new_props}) {
        Pinto::Util::validate_property_name($key);
        $props->{lc $key} = $value;
    }

    #$self->update( {properties => $props} );

    return $self;
}

#-------------------------------------------------------------------------------

sub delete_property {
    my ($self, @prop_keys) = @_;

    my $props = $self->properties;
    delete $props->{lc $_} for @prop_keys;

    $self->update({properties => $props});

    return $self;
}

#-------------------------------------------------------------------------------

sub delete_properties {
    my ($self) = @_;

    self->update({properties => {}});

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
    $self->udpate( {is_locked => 0} );

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

    for my $file ($self->index_file, $self->props_file) {
      return 1 if $self->repo->vcs->status(file => $file->basename);
    }

    return 0;
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
           e => sub { $self->get_property('description')             },
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
