use utf8;
package Pinto::Schema::Result::PackageStack;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Pinto::Schema::Result::PackageStack

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<package_stack>

=cut

__PACKAGE__->table("package_stack");

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

=head2 pin

  data_type: 'integer'
  default_value: null
  is_foreign_key: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "stack",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "package",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "pin",
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

=head1 RELATIONS

=head2 package

Type: belongs_to

Related object: L<Pinto::Schema::Result::Package>

=cut

__PACKAGE__->belongs_to(
  "package",
  "Pinto::Schema::Result::Package",
  { id => "package" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 pin

Type: belongs_to

Related object: L<Pinto::Schema::Result::Pin>

=cut

__PACKAGE__->belongs_to(
  "pin",
  "Pinto::Schema::Result::Pin",
  { id => "pin" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

=head2 stack

Type: belongs_to

Related object: L<Pinto::Schema::Result::Stack>

=cut

__PACKAGE__->belongs_to(
  "stack",
  "Pinto::Schema::Result::Stack",
  { id => "stack" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07015 @ 2012-03-01 18:42:22
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:zk+raQ7ozJVCzgcnTc6qQw

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

use Carp;
use String::Format;

use overload ( '""'     => 'to_string',
               '<=>'    => 'compare',
               fallback => undef );

#-------------------------------------------------------------------------------

sub is_pinned {
    my ($self) = @_;
    return defined $self->pin();
}

#-------------------------------------------------------------------------------

sub compare {
    my ($pstk_a, $pstk_b) = @_;

    confess "Can only compare Pinto::PackageStack objects"
        if __PACKAGE__ ne ref $pstk_a || __PACKAGE__ ne ref $pstk_b;

    return 0 if $pstk_a->id() == $pstk_b->id();

    my $r =   ( $pstk_a->is_pinned()  <=> $pstk_b->is_pinned()  )
           || ( $pstk_a->package()    <=> $pstk_b->package()    );

    return $r;
};

#------------------------------------------------------------------------------

sub to_string {
    my ($self, $format) = @_;

    my %fspec = (
         'n' => sub { $self->package->name()                                   },
         'N' => sub { $self->package->vname()                                  },
         'v' => sub { $self->package->version->stringify()                     },
         'm' => sub { $self->package->distribution->is_devel()  ? 'd' : 'r'    },
         'p' => sub { $self->package->distribution->path()                     },
         'P' => sub { $self->package->distribution->archive()                  },
         's' => sub { $self->package->distribution->is_local()  ? 'l' : 'f'    },
         'S' => sub { $self->package->distribution->source()                   },
         'a' => sub { $self->package->distribution->author()                   },
         'd' => sub { $self->package->distribution->name()                     },
         'D' => sub { $self->package->distribution->vname()                    },
         'w' => sub { $self->package->distribution->version()                  },
         'u' => sub { $self->package->distribution->url()                      },
         'k' => sub { $self->stack->name()                                     },
         'e' => sub { $self->stack->description()                              },
         'u' => sub { $self->stack->mtime()                                    },
         'U' => sub { scalar localtime $self->stack->mtime()                   },
         'y' => sub { $self->is_pinned()                        ? '+' : ' '    },
    );

    # Some attributes are just undefined, usually because of
    # oddly named distributions and other old stuff on CPAN.
    no warnings 'uninitialized';  ## no critic qw(NoWarnings);

    $format ||= $self->default_format();
    return String::Format::stringf($format, %fspec);
}


#-------------------------------------------------------------------------------

sub default_format {

    return '%a/%D/%N/%k';
}

#------------------------------------------------------------------------------
1;

__END__
