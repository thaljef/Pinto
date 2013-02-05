# ABSTRACT: Iterates through commit history

package Pinto::CommitWalker;

use Moose;
use MooseX::MarkAsMethods (autoclean => 1);

use Pinto::Commit;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

has raw_walker => (
  is          => 'ro',
  isa         => 'Git::Raw::Walker',
  required    => 1,
);

#------------------------------------------------------------------------------

sub next {
  my ($self) = @_;

  my $git_commit = $self->raw_walker->next or return;

  return Pinto::Commit->new( raw_commit => $git_commit );
}

#------------------------------------------------------------------------------

sub reset {
  my ($self) = @_;

  $self->raw_walker->reset;

  return $self;
}

#-------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#-------------------------------------------------------------------------------
1;

__END__
