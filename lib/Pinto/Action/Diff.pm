# ABSTRACT: Show the difference between two stacks

package Pinto::Action::Diff;

use Moose;
use MooseX::MarkAsMethods (autoclean => 1);

use Pinto::Types qw(StackName StackDefault StackObject CommitID);

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

extends qw( Pinto::Action );

#------------------------------------------------------------------------------

with qw( Pinto::Role::Colorable );

#------------------------------------------------------------------------------

has left_stack => (
    is       => 'ro',
    isa      => StackName | StackDefault | StackObject,
    required => 1,
);


has left_commit => (
    is       => 'ro',
    isa      => CommitID,
);


has right_stack => (
    is       => 'ro',
    isa      => StackName | StackDefault | StackObject,
    required => 1,
);


has right_commit => (
    is       => 'ro',
    isa      => CommitID,
);

#------------------------------------------------------------------------------

around BUILDARGS => sub {
  my $orig  = shift;
  my $class = shift;

  # Convert hashref back to hash, so notation is easier
  my %args = %{ $class->$orig(@_) };

  # This mess parses the left/right stack attributes into 
  # separate left/right stack and commit attributes.

  for my $lr ( qw(left right) ) {
    my ($s, $c) = ($lr . '_stack', $lr . '_commit');
    @args{$s, $c} = (split /[@]/, $args{$s})
      if defined $args{$s} and $args{$s} =~ /[@]/;

    # split() gives us empty strings,
    # but we can only take undef  
    $args{$s} ||= undef;
  }

  return \%args;
};

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    my $left_stack  = $self->repo->get_stack($self->left_stack);
    my $left_commit = $self->left_commit ? $self->repo->get_commit($self->left_commit) 
                                         : $left_stack->head;

    my $right_stack  = $self->repo->get_stack($self->right_stack);
    my $right_commit = $self->right_commit ? $self->repo->get_commit($self->right_commit) 
                                           : $right_stack->head;

    my $diff = $self->repo->vcs->diff( left_commit_id  => $left_commit->id,
                                       right_commit_id => $right_commit->id );

    my $buffer = '';
    my $cb = sub {
      my ($type, $patch_line) = @_;
      chomp $patch_line;
      return if $type =~ m/(ctx|file|hunk|bin)/;
      my $color = $type eq 'add' ? $self->color_1 : $self->color_3;
      $buffer .= ($color  . $patch_line . $self->color_0 . "\n");
    };

    $diff->patch($cb);

    if ($buffer) {
      my @hfields = ($left_stack, $left_commit, $right_stack, $right_commit);   
      $self->say(sprintf "%s@%s..%s@%s", @hfields);
      $self->chat($buffer);
    }

    return $self->result;
}

#-------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------

1;

__END__
