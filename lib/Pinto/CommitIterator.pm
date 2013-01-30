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

  my $git_commit = $self->walker->next;

  # TODO: Convert git's offset (in minutes) to a DateTime::Timezone
  my $datetime = DateTime->from_epoch(epoch => $git_commit->time);

  return Pinto::Commit->new( id       => $git_commit->id,
                             time     => $datetime,
                             message  => $git_commit->message,
                             username => $git_commit->committer->name, );
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
