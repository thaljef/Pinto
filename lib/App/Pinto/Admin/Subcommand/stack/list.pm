package App::Pinto::Admin::Subcommand::stack::list;

# ABSTRACT: list known stacks (or their contents)

use strict;
use warnings;

#-----------------------------------------------------------------------------

use base 'App::Pinto::Admin::Subcommand';

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

sub command_names { qw(list ls) }

#------------------------------------------------------------------------------

sub opt_spec {
    my ($self, $app) = @_;

    return (
        [ 'format=s' => 'Format of the listing'       ],
        [ 'noinit'   => 'Do not pull/update from VCS' ],
    );
}

#------------------------------------------------------------------------------

sub usage_desc {
    my ($self) = @_;

    my ($command) = $self->command_names();

    my $usage =  <<"END_USAGE";
%c --root=PATH stack $command [OPTIONS]
%c --root=PATH stack $command [OPTIONS] STACK_NAME
END_USAGE

    chomp $usage;
    return $usage;
}

#------------------------------------------------------------------------------

sub validate_args {
    my ($self, $opts, $args) = @_;

    $self->usage_error('Cannot specify multiple stacks')
        if @{ $args } > 1;

    $opts->{format} = eval qq{"$opts->{format}"} ## no critic qw(StringyEval)
        if $opts->{format};

    return 1;
}

#------------------------------------------------------------------------------

sub execute {
    my ($self, $opts, $args) = @_;

    $self->pinto->new_batch(%{$opts});

    # HACK: If an argument is given, it means to list the stack members,
    # not the stacks themselves.  So we run the List action instead of
    # the usual Stack::List action.

    if ( my $stack = $args->[0] ) {
        my $where = { 'stack.name' => $stack };
        $self->pinto->add_action('List', %{$opts}, where => $where);
    }
    else {
        $self->pinto->add_action($self->action_name(), %{$opts});
    }

    my $result = $self->pinto->run_actions();

    return $result->is_success() ? 0 : 1;
}

#------------------------------------------------------------------------------

1;

__END__
