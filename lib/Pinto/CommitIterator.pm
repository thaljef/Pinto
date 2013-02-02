# ABSTRACT: Represents 

package Pinto::CommitIterator;

use Moose;

use Pinto::Commit;

#------------------------------------------------------------------------------

has walker => (
  is          => 'ro',
  isa         => 'Git::Raw::Walker',
  required    => 1,
);

#------------------------------------------------------------------------------

sub next {
  my ($self) = @_;

  my $git_commit = $self->walker->next or return;

  return Pinto::Commit->new( $git_commit );
}

#------------------------------------------------------------------------------

sub reset {
  my ($self) = @_;

  $self->walker->reset;

  return $self;
}

#-------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#-------------------------------------------------------------------------------
1;

__END__
