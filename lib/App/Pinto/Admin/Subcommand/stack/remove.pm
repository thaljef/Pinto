package App::Pinto::Admin::Subcommand::stack::remove;

# ABSTRACT: delete a stack

use strict;
use warnings;

#-----------------------------------------------------------------------------

use base 'App::Pinto::Admin::Subcommand';

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

sub command_names { qw(remove rm delete del) }

#------------------------------------------------------------------------------

sub opt_spec {
    my ($self, $app) = @_;

    return (
        [ 'message|m=s'     => 'Prepend a message to the VCS log'  ],
        [ 'nocommit'        => 'Do not commit changes to VCS'      ],
        [ 'noinit'          => 'Do not pull/update from VCS'       ],
        [ 'tag=s'           => 'Specify a VCS tag name'            ],
    );


}

#------------------------------------------------------------------------------
sub validate_args {
    my ($self, $opts, $args) = @_;

    $self->usage_error('Must specify a stack name')
        if not @{$args};

    return 1;
}

#------------------------------------------------------------------------------

sub usage_desc {
    my ($self) = @_;

    my ($command) = $self->command_names();

    my $usage =  <<"END_USAGE";
%c --root=PATH stack $command [OPTIONS] STACK_NAME
END_USAGE

    chomp $usage;
    return $usage;
}

#------------------------------------------------------------------------------

sub execute {
    my ($self, $opts, $args) = @_;

    $self->pinto->new_batch(%{$opts});
    $self->pinto->add_action($self->action_name(), %{$opts}, stack => $args->[0]);
    my $result = $self->pinto->run_actions();

    return $result->is_success() ? 0 : 1;
}

#------------------------------------------------------------------------------

1;

__END__
