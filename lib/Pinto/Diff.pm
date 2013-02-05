# ABSTRACT: Represents difference between two stacks

package Pinto::Diff;

use Moose;
use MooseX::MarkAsMethods (autoclean => 1);

use Pinto::Util qw(itis);

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

has raw_diff => (
  is          => 'ro',
  isa         => 'Git::Raw::Diff',
  required    => 1,
);

#------------------------------------------------------------------------------

sub patch {
    my ($self, $cb) = @_;

    $self->raw_diff->patch($cb);

    return $self;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#-------------------------------------------------------------------------------
1;

__END__
