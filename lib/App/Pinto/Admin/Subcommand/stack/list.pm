package App::Pinto::Admin::Subcommand::stack::list;

# ABSTRACT: list names of stacks (or their contents)

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

=pod

=head1 SYNOPSIS

  pinto-admin --root=/some/dir stack list [OPTIONS]
  pinto-admin --root=/some/dir stack list [OPTIONS] STACK_NAME

=head1 DESCRIPTION

This command lists the names and descriptions of the stacks in the
repository.  Or it will list the members of a particular stack.

=head1 SUBCOMMAND ARGUMENTS

If given no arguments, then the names and descriptions of the stacks
are shown.  If given a C<STACK_NAME> argument, then the members of
that stack will be listed.  So the following two commands are
equivalent:

$> pinto-admin --root=/some/dir list --stack=development
$> pinto-admin --root=/some/dir stack list development

=head1 SUBCOMMAND OPTIONS

=over 4

=item --format=FORMAT_SPECIFICATION

Sets the format of each record in the listing with C<printf>-style
placeholders.  Valid placeholders are:

  Placeholder    Meaning
  -----------------------------------------------------------------------------
  %k             Stack name
  %e             Stack description
  %u             Last modification time of stack (as integer)
  %U             Last modification time of stack (as human-readable string)
  %%             A literal '%'

=item --noinit

Prevents L<Pinto> from pulling/updating the repository from the VCS
before the operation.  This is only relevant if you are using a
VCS-based storage mechanism.  This can speed up operations
considerably, but should only be used if you *know* that your working
copy is up-to-date and you are going to be the only actor touching the
Pinto repository within the VCS.

=back

=cut
