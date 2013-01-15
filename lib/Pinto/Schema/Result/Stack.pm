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

=head2 properties

  data_type: 'text'
  default_value: null
  is_nullable: 1

=head2 head

  data_type: 'integer'
  default_value: null
  is_foreign_key: 1
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
  "properties",
  { data_type => "text", default_value => \"null", is_nullable => 1 },
  "head",
  {
    data_type      => "integer",
    default_value  => \"null",
    is_foreign_key => 1,
    is_nullable    => 1,
  },
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

=head1 RELATIONS

=head2 head

Type: belongs_to

Related object: L<Pinto::Schema::Result::Kommit>

=cut

__PACKAGE__->belongs_to(
  "head",
  "Pinto::Schema::Result::Kommit",
  { id => "head" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
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


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-01-08 14:22:13
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:DHQJRHZJL+1jGe7Xp3IiPg

#-------------------------------------------------------------------------------

# ABSTRACT: Represents a named set of Packages

#-------------------------------------------------------------------------------

# VERSION

#-------------------------------------------------------------------------------


use MooseX::Types::Moose qw(Bool);

use String::Format;
use JSON qw(encode_json decode_json);

use Pinto::Util qw(itis);
use Pinto::Exception qw(throw);
use Pinto::IndexWriter;

use overload ( '""'  => 'to_string',
               '<=>' => 'numeric_compare',
               'cmp' => 'string_compare' );

#------------------------------------------------------------------------------

__PACKAGE__->inflate_column( 'properties' => { inflate => sub { decode_json($_[0] || '{}') },
                                               deflate => sub { encode_json($_[0] || {}) } }
);

#------------------------------------------------------------------------------

sub FOREIGNBUILDARGS {
  my ($class, $args) = @_;

  $args ||= {};
  $args->{is_default} ||= 0;
  $args->{properties}   = '{}';
  $args->{name_canonical} = lc $args->{name};

  return $args;
}

#------------------------------------------------------------------------------

before is_default => sub {
    my ($self, @args) = @_;
    throw 'You cannot directly set is_default.  Use mark_as_default' if @args;
};

#------------------------------------------------------------------------------

sub open {
    my ($self, %args) = @_;

    $args{message}  ||= '';     # Message usually updated when we commmit
    $args{username} ||= $self->config->username;

    throw "Stack $self is locked and cannot be modified" if $self->is_locked;

    my $parent = $self->has_head ? $self->head : $self->result_source->schema->get_root_kommit;
    my $kommit = $self->result_source->schema->create_kommit(\%args);

    $kommit->add_parent($parent);
    $self->set_head($kommit);

    $self->debug("Opened new head $kommit on stack $self");
    
    return $self;
}

#------------------------------------------------------------------------------

sub close {
    my ($self, %args) = @_;

    $self->head->finalize( %args );
    $self->write_index if $self->has_changed;

    return $self;
}

#------------------------------------------------------------------------------

sub delete {
  my ($self) = @_;

  throw "Stack $self is locked and cannot be deleted" if $self->is_locked;

  # There is a circular ref between stacks and registration_changes via
  # the registration_changes and the head kommit.  So deleting a stack 
  # will violate referential integrity To get around this, we must delete 
  # the registrations *before* deleting the stack itself.  If we let the 
  # database cascade deletes for us, the registrations would be deleted 
  # *after* the stack.

  $self->open;
  $self->registrations->delete;
  return $self->next::method;

}

#------------------------------------------------------------------------------

sub write_index {
    my ($self) = @_;

    my $writer = Pinto::IndexWriter->new( stack => $self,
                                          logger => $self->logger,
                                          config => $self->config );
    $writer->write_index;

    return $self;
}

#------------------------------------------------------------------------------

sub registration {
    my ($self, %args) = @_;

    my $pkg_name = ref $args{package} ? $args{package}->name
                                      : $args{package};

    my $attrs = { prefetch => {package => 'distribution'} };
    my $where = {'package.name' => $pkg_name};

    return $self->find_related(registrations => $where, $attrs);
}

#------------------------------------------------------------------------------

sub registered_distribution_ids {
    my ($self) = @_;

    my $attrs = { columns => 'distribution', distinct => 1 };
    my $ids = $self->registrations->search({}, $attrs)->get_column('distribution');

    return $ids->all;
}

#------------------------------------------------------------------------------

sub registered_distributions {
    my ($self, %args) = @_;

    my $where = {};
    $where->{archive} = {like => "%$args{matching}%"} if $args{matching};

    my $attrs = { distinct => 1,
                  order_by => [ qw(author archive) ] };

    my $rs = $self->result_source->schema->resultset('Distribution');

    return $rs->search(undef, $attrs);
}

#------------------------------------------------------------------------------

sub registered_distributions_by_revision {
    my ($self, %args) = @_;

    my @dist_ids = $self->registered_distribution_ids;

    my $where = { 'revision.stack' => $self->id, 
                  'me.id'          => {-in => \@dist_ids} };

    $where->{archive} = {like => "%$args{matching}%"} if $args{matching};

    my $attrs = { distinct => 1,
                  prefetch => 'packages',
                  order_by => 'revision DESC',
                  join     => {registration_changes => 'revision'} };

    my $rs = $self->result_source->schema->resultset('Distribution');

    return $rs->search($where, $attrs);
}

#------------------------------------------------------------------------------

sub total_registered_distributions {
    my ($self) = @_;

    my $attrs = {columns => 'distribution', distinct => 1};

    return $self->registrations({}, $attrs)->count;
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

sub copy_deeply {
    my ($self, $changes) = @_;

    my $copy = $self->copy($changes);
    $self->copy_registrations(to => $copy);

    return $copy;
}

#------------------------------------------------------------------------------

sub copy_registrations {
    my ($self, %args) = @_;

    my $to_stack = $args{to};
    $self->info("Copying registrations for stack $self into stack $to_stack");

    my $where = {stack => $self->id};
    my $attrs = {result_class => 'DBIx::Class::ResultClass::HashRefInflator'};
    my $rs = $self->result_source->schema->resultset('Registration');

    my @rows = $rs->search($where, $attrs)->all;
    for (@rows) { delete $_->{id}; $_->{stack} = $to_stack->id; } 

    $rs->populate(\@rows);

    return $self;
}

#------------------------------------------------------------------------------

sub mark_as_default {
    my ($self) = @_;

    if ($self->is_default) {
        $self->warning("Stack $self is already the default");
        return 0;
    }

    # TODO: wrap in txn

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

    my $props = $self->properties;
    while (my ($key, $value) = each %{$new_props}) {
        Pinto::Util::validate_property_name($key);
        $props->{lc $key} = $value;
    }

    $self->update( {properties => $props} );

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

sub is_locked {
    my ($self) = @_;

    return $self->get_property('pinto-locked');
}

#------------------------------------------------------------------------------

sub lock {
    my ($self) = @_;

    if ($self->is_locked) {
      $self->warning("Stack $self is already locked");
      return 0;
    }

    $self->notice("Locking stack $self");
    $self->set_property('pinto-locked' => 1);
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
    $self->delete_property('pinto-locked');
    return 1;
}

#------------------------------------------------------------------------------

sub has_head {
    my ($self) = @_;

    return defined $self->head;
}

#------------------------------------------------------------------------------

sub set_head {
  my ($self, $new_head) = @_;

  $self->update( {head => $new_head} );

  return $self;
}

#------------------------------------------------------------------------------

sub has_changed {
    my ($self) = @_;

    return $self->head->registration_changes->count > 0;
}

#------------------------------------------------------------------------------

sub has_not_changed {
    my ($self) = @_;

    return ! $self->has_changed;
}

#------------------------------------------------------------------------------

sub history {
    my ($self) = @_;

    # TODO: this return an iterator, so we don't have to slurp the entire
    # history into memory.  To do this, we need an option to tell ancestors()
    # whether or not to include $self in the results.

    return ($self->head, $self->head->ancestors);
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
           k => sub { $self->name                                                      },
           M => sub { $self->is_default                                    ? '*' : ' ' },
           L => sub { $self->is_locked                                     ? 'X' : ' ' },
           G => sub { $self->has_head ? $self->head->message                     : ''  },
           J => sub { $self->has_head ? $self->head->username                    : ''  },
           U => sub { $self->has_head ? $self->head->timestamp->strftime('%c')   : ''  },
           e => sub { $self->get_property('description')                               },
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
