use utf8;
package Pinto::Schema::Result::Registration;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Pinto::Schema::Result::Registration

=cut

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

=head1 TABLE: C<registration>

=cut

__PACKAGE__->table("registration");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 stack

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 package

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 package_name

  data_type: 'text'
  is_nullable: 0

=head2 distribution

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 is_pinned

  data_type: 'boolean'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "stack",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "package",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "package_name",
  { data_type => "text", is_nullable => 0 },
  "distribution",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "is_pinned",
  { data_type => "boolean", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<stack_package_name_unique>

=over 4

=item * L</stack>

=item * L</package_name>

=back

=cut

__PACKAGE__->add_unique_constraint("stack_package_name_unique", ["stack", "package_name"]);

=head2 C<stack_package_unique>

=over 4

=item * L</stack>

=item * L</package>

=back

=cut

__PACKAGE__->add_unique_constraint("stack_package_unique", ["stack", "package"]);

=head1 RELATIONS

=head2 distribution

Type: belongs_to

Related object: L<Pinto::Schema::Result::Distribution>

=cut

__PACKAGE__->belongs_to(
  "distribution",
  "Pinto::Schema::Result::Distribution",
  { id => "distribution" },
  { is_deferrable => 0, on_delete => "CASCADE", on_update => "NO ACTION" },
);

=head2 package

Type: belongs_to

Related object: L<Pinto::Schema::Result::Package>

=cut

__PACKAGE__->belongs_to(
  "package",
  "Pinto::Schema::Result::Package",
  { id => "package" },
  { is_deferrable => 0, on_delete => "CASCADE", on_update => "NO ACTION" },
);

=head2 stack

Type: belongs_to

Related object: L<Pinto::Schema::Result::Stack>

=cut

__PACKAGE__->belongs_to(
  "stack",
  "Pinto::Schema::Result::Stack",
  { id => "stack" },
  { is_deferrable => 0, on_delete => "CASCADE", on_update => "NO ACTION" },
);

=head1 L<Moose> ROLES APPLIED

=over 4

=item * L<Pinto::Role::Schema::Result>

=back

=cut


with 'Pinto::Role::Schema::Result';


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2012-12-01 21:41:02
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:5FuY4cqJpXjQRvLbAhQbXw

#------------------------------------------------------------------------------

# ABSTRACT: Represents the relationship between a Package and a Stack

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

use Carp;
use String::Format;

use Pinto::Util qw(itis);
use Pinto::Exception qw(throw);

use overload ( '""'     => 'to_string',
               'cmp'    => 'string_compare',
               '<=>'    => 'compare',
               fallback => undef );

#-------------------------------------------------------------------------------

sub sqlt_deploy_hook {
   my ($self, $sqlt_table) = @_;

   for my $event (qw(insert delete)) {

    # The name of the table that contains the incoming/outgoing
    # record depends on whether we are inserting or deleting it.
    my $tb       = ($event eq 'insert') ? 'new' : 'old';

    # The last revision on the stack should be the head.
    # TODO: assert that the revision is open before writing change
    my $revision = qq{ SELECT MAX(revision.id) FROM revision WHERE stack = $tb.stack };
    my $kommit   = qq{ SELECT kommit.id FROM kommit JOIN revision ON revision.kommit = kommit.id WHERE revision.id = ($revision) };

    # If there is already a change record for this package 
    # in this kommit,then just replace the existing one.
    my $sql      = qq{ INSERT OR REPLACE INTO registration_change (event, package, package_name, distribution, is_pinned, kommit) };
       $sql     .= qq{ VALUES ('$event', $tb.package, $tb.package_name, $tb.distribution, $tb.is_pinned, ($kommit)); };

    $sqlt_table->schema->add_trigger(
      name                => "after_${event}_registration",
      table               => $sqlt_table,
      perform_action_when => 'after',
      database_events     => [$event],
      action              => $sql,
    );
  }

    return;
 }

#-------------------------------------------------------------------------------

sub FOREIGNBUILDARGS {
    my ($class, $args) = @_;

    # Should we default these here or in the database?

    $args ||= {};
    $args->{is_pinned} ||= 0;

    return $args;
}

#-------------------------------------------------------------------------------

sub update { throw 'Updates to '.  __PACKAGE__ . ' are not allowed'; }

#------------------------------------------------------------------------------

sub pin {
    my ($self) = @_;

    throw "$self is already pinned" if $self->is_pinned;

    $self->delete;
    $self->is_pinned(1);
    $self->insert;

    return $self;
}

#-------------------------------------------------------------------------------

sub unpin {
    my ($self) = @_;

    throw "$self is not pinned" if not $self->is_pinned;

    $self->delete;
    $self->is_pinned(0);
    $self->insert;

    return $self;
}

#-------------------------------------------------------------------------------

sub merge {
    my ($self, %args) = @_;

    my $to_stk = $args{to};

    my $from_pkg = $self->package;
    my $to_reg   = $to_stk->registration(package => $from_pkg);

    # CASE 1:  The package is not registered on the target stack,
    # so we can go ahead and just add it there.

    if (not defined $to_reg) {
         $self->debug("Adding package $from_pkg to stack $to_stk");
         $self->copy( {stack => $to_stk} );
         return (0, 1);
     }

    # CASE 2:  The exact same package is in both the source
    # and the target stacks, so we don't have to merge.  But
    # if the source is pinned, then we should also copy the
    # pin to the target.

    if ($self == $to_reg) {
        $self->debug("$self and $to_reg are the same");
        if ($self->is_pinned and not $to_reg->is_pinned) {
            $self->debug("Adding pin to $to_reg");
            $to_reg->pin;
            return (0, 1);
        }
        return (0, 0);
    }

    # CASE 3:  The package in the target stack is newer than the
    # one in the source stack.  If the package in the source stack
    # is pinned, then we have a conflict, so whine.  If it is not
    # pinned then there is nothing to do because the package in
    # the target stack is already newer.

    if ($to_reg > $self) {
        if ( $self->is_pinned ) {
            $self->warning("$self is pinned to a version older than $to_reg");
            return (1, 0);
        }
        $self->debug("$to_reg is already newer than $self");
        return (0, 0);
    }


    # CASE 4:  The package in the target stack is older than the
    # one in the source stack.  If the package in the target stack
    # is pinned, then we have a conflict, so whine.  If it is not
    # pinned, then upgrade the package in the target stack with
    # the newer package in the source stack.

    if ($to_reg < $self) {
        if ( $to_reg->is_pinned ) {
            $self->warning("$to_reg is pinned to a version older than $self");
            return (1, 0);
        }
        my $from_pkg = $self->package;
        $self->info("Upgrading $to_reg to $from_pkg");
        $to_reg->delete;
        $self->copy( {stack => $to_reg->stack} );
        return (0, 1);
    }

    # CASE 5:  The above logic should cover all possible scenarios.
    # So if we get here then either our logic is flawed or something
    # weird has happened in the database.

    throw "Unable to merge $self into $to_reg";
}

#-------------------------------------------------------------------------------

sub compare {
    my ($reg_a, $reg_b) = @_;

    my $pkg = __PACKAGE__;
    throw "Can only compare $pkg objects"
        if not ( itis($reg_a, $pkg) && itis($reg_b, $pkg) );

    return 0 if $reg_a->id == $reg_b->id;

    return $reg_a->package <=> $reg_b->package;
};

#------------------------------------------------------------------------------

sub string_compare {
    my ($reg_a, $reg_b) = @_;

    my $pkg = __PACKAGE__;
    throw "Can only compare $pkg objects"
        if not ( itis($reg_a, $pkg) && itis($reg_b, $pkg) );

    return 0 if $reg_a->id == $reg_b->id;

    return    ($reg_a->package->distribution->author_canonical cmp $reg_b->package->distribution->author_canonical)
           || ($reg_a->package->distribution->vname            cmp $reg_b->package->distribution->vname)
           || ($reg_a->package->vname                          cmp $reg_b->package->vname);
}

#------------------------------------------------------------------------------

sub to_string {
    my ($self, $format) = @_;

    # my ($pkg, $file, $line) = caller;
    # warn __PACKAGE__ . " stringified from $file at line $line";

    my %fspec = (
         n => sub { $self->package->name                                              },
         N => sub { $self->package->vname                                             },
         v => sub { $self->package->version                                           },
         m => sub { $self->package->distribution->is_devel  ? 'd' : 'r'               },
         p => sub { $self->package->distribution->path                                },
         P => sub { $self->package->distribution->native_path                         },
         f => sub { $self->package->distribution->archive                             },
         s => sub { $self->package->distribution->is_local  ? 'l' : 'f'               },
         S => sub { $self->package->distribution->source                              },
         a => sub { $self->package->distribution->author                              },
         A => sub { $self->package->distribution->author_canonical                    },
         d => sub { $self->package->distribution->name                                },
         D => sub { $self->package->distribution->vname                               },
         w => sub { $self->package->distribution->version                             },
         u => sub { $self->package->distribution->url                                 },
         k => sub { $self->stack->name                                                },
         y => sub { $self->is_pinned                        ? '*' : ' '               },
    );

    # Some attributes are just undefined, usually because of
    # oddly named distributions and other old stuff on CPAN.
    no warnings 'uninitialized';  ## no critic qw(NoWarnings);

    $format ||= $self->default_format();
    return String::Format::stringf($format, %fspec);
}


#-------------------------------------------------------------------------------

sub default_format {

    return '%A/%D/%N/%k';
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------
1;

__END__
