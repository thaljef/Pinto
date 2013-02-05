# ABSTRACT: Show the difference between two stacks

package Pinto::Action::Diff;

use Moose;
use MooseX::Types::Moose qw(Bool);
use MooseX::MarkAsMethods (autoclean => 1);

use Term::ANSIColor qw(color);

use Pinto::Types qw(StackName StackObject);

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

extends qw( Pinto::Action );

#------------------------------------------------------------------------------

has left_stack => (
    is       => 'ro',
    isa      => StackName | StackObject,
    required => 1,
);


has right_stack => (
    is       => 'ro',
    isa      => StackName | StackObject,
    required => 1,
);


has nocolor => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    my $left  = $self->repo->get_stack($self->left_stack);
    my $right = $self->repo->get_stack($self->right_stack);

    my $diff = $self->repo->vcs->diff( left_commit_id  => $left->last_commit_id,
                                       right_commit_id => $right->last_commit_id );

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

    $self->say("$left..$right");
    $self->say($buffer);

    return $self->result;
}

#-------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------

1;

__END__
