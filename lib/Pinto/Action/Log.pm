# ABSTRACT: Show revision log for a stack

package Pinto::Action::Log;

use Moose;
use MooseX::Types::Moose qw(Bool Str);
use MooseX::MarkAsMethods (autoclean => 1);

use Term::ANSIColor qw(color);

use Pinto::Types qw(StackName StackDefault CommitID);

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

extends qw( Pinto::Action );

#------------------------------------------------------------------------------

has stack => (
    is        => 'ro',
    isa       => StackName | StackDefault,
    default   => undef,
);


has commit => (
    is        => 'ro',
    isa       => CommitID,
);


has format => (
    is      => 'ro',
    isa     => Str,
    builder => '_build_format',
    lazy    => 1,
);


has nocolor => (
    is        => 'ro',
    isa       => Bool,
    default   => 0,
);

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    if (my $commit_id = $self->commit) {

        # Just show the one commit
        my $commit = $self->repo->get_commit($commit_id);
        $self->say( $commit->to_string($self->format) ); 
    }
    else {

        # Show all commits for the stack
        my $stack = $self->repo->get_stack($self->stack);
        my $iterator = $self->repo->vcs->history(branch => $stack->name_canonical);

        while ( defined(my $commit = $iterator->next) ) {
            $self->say( $commit->to_string($self->format) ); 
        }
    }

    return $self->result;
}

#------------------------------------------------------------------------------

sub _build_format {
    my ($self) = @_;

    my $yellow = $self->nocolor ? '' : color('bold yellow');
    my $reset  = $self->nocolor ? '' : color('reset');

    return <<"END_FORMAT";
${yellow}commit %I${reset}
Date: %u
User: %j 

%{4}G
END_FORMAT

}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------

1;

__END__
