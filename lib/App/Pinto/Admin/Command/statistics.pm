package App::Pinto::Admin::Command::statistics;

# ABSTRACT: report statistics about the repository

use strict;
use warnings;

#-----------------------------------------------------------------------------

use base 'App::Pinto::Admin::Command';

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

sub command_names { return qw( statistics stats ) }

#------------------------------------------------------------------------------

sub opt_spec {
    my ($self, $app) = @_;

    return (
        [ 'noinit'      => 'Do not pull/update from VCS' ],
    );
}

#------------------------------------------------------------------------------

sub usage_desc {
    my ($self) = @_;

    my ($command) = $self->command_names();

 my $usage =  <<"END_USAGE";
%c --root=PATH $command [OPTIONS]
END_USAGE

    chomp $usage;
    return $usage;
}


#------------------------------------------------------------------------------

1;

__END__

=head1 SYNOPSIS

  pinto-admin --root=/some/dir statistics [OPTIONS]

=head1 DESCRIPTION

This command reports some statistics about the repository

=head1 COMMAND ARGUMENTS

None

=head1 COMMAND OPTIONS

=over 4

=item --noinit

Prevents L<Pinto> from pulling/updating the repository from the VCS
before the operation.  This is only relevant if you are using a
VCS-based storage mechanism.  This can speed up operations
considerably, but should only be used if you *know* that your working
copy is up-to-date and you are going to be the only actor touching the
Pinto repository within the VCS.

=back

=cut
