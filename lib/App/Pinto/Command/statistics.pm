# ABSTRACT: report statistics about the repository

package App::Pinto::Command::statistics;

use strict;
use warnings;

#-----------------------------------------------------------------------------

use base 'App::Pinto::Command';

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

# TODO: Add a --stack option, just like the "list" command.

#------------------------------------------------------------------------------

sub command_names { return qw( statistics stats ) }

#------------------------------------------------------------------------------

sub validate_args {
    my ( $self, $opts, $args ) = @_;

    $self->usage_error('Multiple arguments are not allowed')
        if @{$args} > 1;

    $opts->{stack} = $args->[0]
        if $args->[0];

    return 1;
}

#------------------------------------------------------------------------------
1;

__END__

=head1 SYNOPSIS

  pinto --root=REPOSITORY_ROOT statistics [STACK]

=head1 DESCRIPTION

!! THIS COMMAND IS EXPERIMENTAL !!

This command reports some statistics about the repository.

=head1 COMMAND ARGUMENTS

The argument is the name of the stack you wish to see the statistics for. If
you do not specify a stack, then the default stack will be used.

=head1 COMMAND OPTIONS

None.

=cut
