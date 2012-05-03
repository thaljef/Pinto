package App::Pinto::Admin::Command::stacks;

# ABSTRACT: show available stacks

use strict;
use warnings;

#-----------------------------------------------------------------------------

use base 'App::Pinto::Admin::Command';

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

sub opt_spec {
    my ($self, $app) = @_;

    return (
        [ 'format=s' => 'Format of the listing' ],
    );
}

#------------------------------------------------------------------------------

sub usage_desc {
    my ($self) = @_;

    my ($command) = $self->command_names;

    my $usage =  <<"END_USAGE";
%c --root=PATH $command [OPTIONS]
END_USAGE

    chomp $usage;
    return $usage;
}

#------------------------------------------------------------------------------

sub validate_args {
    my ($self, $opts, $args) = @_;

    $self->usage_error('No arguments are allowed')
        if @{ $args };

    $opts->{format} = eval qq{"$opts->{format}"} ## no critic qw(StringyEval)
        if $opts->{format};

    return 1;
}

#------------------------------------------------------------------------------
1;

__END__

=pod

=head1 SYNOPSIS

  pinto-admin --root=/some/dir stacks [OPTIONS]
  pinto-admin --root=/some/dir stacks [OPTIONS]

=head1 DESCRIPTION

This command lists the names (and some other details) of all the
stacks available in the repository.

=head1 COMMAND ARGUMENTS

None.

=head1 COMMAND OPTIONS

=over 4

=item --format=FORMAT_SPECIFICATION

Format each record in the listing with C<printf>-style placeholders.
Valid placeholders are:

  Placeholder    Meaning
  -----------------------------------------------------------------------------
  %k             Stack name
  %e             Stack description
  %M             Stack master status                               (*) = master
  %U             Stack last-modified-on
  %j             Stack last-modified-by
  %%             A literal '%'

=back

=cut
