# ABSTRACT: Represents 

package Pinto::Patch;

use Moose;
use MooseX::MarkAsMethods (autoclean => 1);

use Pinto::RegistryEntry;
use Pinto::Util qw(itis);

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

has stack => (
  is         => 'ro',
  isa        => 'Pinto::Schema::Result::Stack',
  required   => 1,
);


has diff => (
  is          => 'ro',
  isa         => 'Pinto::Diff',
  required    => 1,
);

#------------------------------------------------------------------------------

sub apply {
    my ($self) = @_;

    my @adds;
    my @dels;

    my $cb = sub {
      my ($type, $patch_line) = @_;
      $DB::single = 1;
      push @adds, substr $patch_line, 1  if $type eq 'add';
      push @dels, substr $patch_line, 1  if $type eq 'del';
    };

    $self->diff->patch($cb);

    for my $del (@dels) {
      my $entry = Pinto::RegistryEntry->new($del);
      $self->stack->registry->delete( entry => $entry );
    }

    for my $add (@adds) {
      my $entry = Pinto::RegistryEntry->new($add);
      $self->stack->registry->add( entry => $entry );
    }

    return $self;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#-------------------------------------------------------------------------------
1;

__END__
