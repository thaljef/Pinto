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

  pinto-admin --root=/some/dir statistics

=head1 DESCRIPTION

This command reports some statistics about the repository

=head1 COMMAND ARGUMENTS

None

=head1 COMMAND OPTIONS

None

=back

=cut
