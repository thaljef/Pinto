# ABSTRACT: Show the difference between two stacks

package Pinto::Action::Diff;

use Moose;
use MooseX::Types::Moose qw(Bool);
use MooseX::MarkAsMethods (autoclean => 1);

use Term::ANSIColor qw(color);

use Pinto::Types qw(StackName StackDefault StackObject CommitID);

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

extends qw( Pinto::Action );

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


has nocolor => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
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
    my ($red, $green, $reset) = $self->nocolor 
                                ? ('') x 3
                                : (color('red'), color('green'), color('reset'));

    my $cb = sub {
      my ($type, $patch_line) = @_;
      # TODO: Decide if/how to display these types...
      return if $type =~ m/(ctx|file|hunk|bin)/;
      my $color = $type eq 'add' ? $green : $red;
      $buffer .= ($color  . $patch_line . $reset);
    };

    $diff->patch($cb);

    if ($buffer) {
      my @hfields = ($left_stack, $left_commit, $right_stack, $right_commit);   
      $self->say(sprintf "%s@%s..%s@%s", @hfields);
      $self->say($buffer);
    }

    return $self->result;
}

#-------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------

1;

__END__
