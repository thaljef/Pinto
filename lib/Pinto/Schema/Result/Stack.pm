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

=head2 has_changed

  data_type: 'integer'
  is_nullable: 0

=head2 properties

  data_type: 'text'
  default_value: null
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
  "has_changed",
  { data_type => "integer", is_nullable => 0 },
  "properties",
  { data_type => "text", default_value => \"null", is_nullable => 1 },
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

=head2 revisions

Type: has_many

Related object: L<Pinto::Schema::Result::Revision>

=cut

__PACKAGE__->has_many(
  "revisions",
  "Pinto::Schema::Result::Revision",
  { "foreign.stack" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head1 L<Moose> ROLES APPLIED

=over 4

=item * L<Pinto::Role::Schema::Result>

=back

=cut


with 'Pinto::Role::Schema::Result';


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2012-11-30 01:11:49
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:CvLbc7nuzCHtIQh66u27KQ

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
  $args->{is_default}  ||= 0;
  $args->{has_changed} ||= 0;
  $args->{name_canonical} = lc $args->{name};

  return $args;
}

#------------------------------------------------------------------------------

before delete => sub {
    my ($self, @args) = @_;
    throw 'You cannot remove the default stack' if $self->is_default;
};

#------------------------------------------------------------------------------

before is_default => sub {
    my ($self, @args) = @_;
    throw 'You cannot directly set is_default.  Use mark_as_default' if @args;
};

#------------------------------------------------------------------------------

sub close {
    my ($self, @args) = @_;

    throw "Stack $self is not open for revision"
      if $self->head_revision->kommit->is_committed;

    $self->update( {has_changed => 0} );
    $self->head_revision->close(@args);

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
    $self->copy_revisions(to => $copy);
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

sub copy_revisions {
    my ($self, %args) = @_;

    my $to_stack = $args{to};
    $self->info("Copying history for stack $self into stack $to_stack");

    my $where = {stack => $self->id};
    my $attrs = {result_class => 'DBIx::Class::ResultClass::HashRefInflator'};
    my $rs = $self->result_source->schema->resultset('Revision');

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

    $self->debug('Marking all stacks as non-default');
    my $rs = $self->result_source->resultset->search;
    $rs->update_all( {is_default => 0} );

    $self->warning("Marking stack $self as default");
    $self->update( {is_default => 1} );

    return 1;
}

#------------------------------------------------------------------------------

sub mark_as_changed {
    my ($self) = @_;

    $self->update( {has_changed => 1} ) unless $self->has_changed;

    return $self;
}

#------------------------------------------------------------------------------

sub head_revision {
    my ($self) = @_;

    my $head_id = $self->revisions->get_column('id')->max;

    return $self->find_related( revisions => {id => $head_id} );
}

#------------------------------------------------------------------------------

sub revision {
    my ($self, %args) = @_;

    return $self->revisions if not defined $args{number};

    return $self->find_related( revisions => {number => $args{number}} );
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

#-------------------------------------------------------------------------------

sub merge {
    my ($self, %args) = @_;

    my $to_stk = $args{to};

    my ($conflicts, $did_merge);
    for my $reg ($self->registrations) {
        $self->info("Merging package $reg into stack $to_stk");
        my ($c, $m) = $reg->merge(%args);
        $conflicts += $c;
        $did_merge += $m;
    }

    throw "There were $conflicts conflicts.  Merge aborted" if $conflicts;

    return $did_merge;
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
           k => sub { $self->name                                                },
           M => sub { $self->is_default                          ? '*' : ' '     },
           j => sub { $self->head_revision->kommit->committed_by                 },
           u => sub { $self->head_revision->kommit->committed_on->strftime('%c') },
           e => sub { $self->get_property('description')                         },
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
