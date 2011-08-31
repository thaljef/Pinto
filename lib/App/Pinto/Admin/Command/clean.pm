package App::Pinto::Admin::Command::clean;

# ABSTRACT: remove all distributions that are not in the index

use strict;
use warnings;

use IO::Interactive;

#-----------------------------------------------------------------------------

use base 'App::Pinto::Admin::Command';

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

sub opt_spec {
    my ($self, $app) = @_;

    # TODO: add option to prompt before cleaning each dist

    return ( $self->SUPER::opt_spec(),

        [ 'message|m=s' => 'Prepend a message to the VCS log' ],
        [ 'nocommit'    => 'Do not commit changes to VCS' ],
        [ 'noinit'      => 'Do not pull/update from VCS' ],
        [ 'tag=s'       => 'Specify a VCS tag name' ]
    );
}

#------------------------------------------------------------------------------

sub validate_args {
    my ($self, $opts, $args) = @_;

    $self->SUPER::validate_args($opts, $args);

    $self->usage_error('Arguments are not allowed') if @{ $args };

    return 1;
}

#------------------------------------------------------------------------------

sub execute {
    my ($self, $opts, $args) = @_;

    $self->pinto->new_action_batch( %{$opts} );
    $self->pinto->add_action('Clean', %{$opts});

    $self->prompt_for_confirmation() if IO::Interactive::is_interactive();

    my $result = $self->pinto->run_actions();
    return $result->is_success() ? 0 : 1;
}

#------------------------------------------------------------------------------

sub prompt_for_confirmation {
    my ($self) = @_;

    print <<'END_MESSAGE';
Cleaning the repository will remove all distributions that is not in
the current index.  As a result, it will become impossible to install
older versions of distributions from your repository.

Once cleaned, the only way to get those distributions back in your
repository is to roll back your VCS (if applicable), or manually fetch
them from CPAN (if they can be found) and add them to your repository.

END_MESSAGE

    my $answer = '';

    until ($answer =~ m/[yn]/ix) {
        print "Are you sure you want to proceed? [Y/N]: ";
        chomp( $answer = uc <STDIN> );
    }

    exit 0 if $answer eq 'N';
    return 1;
}

#------------------------------------------------------------------------------

1;

__END__

=head1 SYNOPSIS

  pinto-admin --repos=/some/dir clean [OPTIONS]

=head1 DESCRIPTION


This command deletes any distribution in the repository that is not
currently listed in the index.  This usually happens automatically,
unless you've set the C<nocleanup> parameter in your repository
configuration.  Beware that running the C<clean> command will make it
impossible to install outdated distributions from your repository, and
the only way to get them back is to use the C<add> command again (or
rollback, if using VCS).

=head1 COMMAND ARGUMENTS

None.

=head1 COMMAND OPTIONS

=over 4

=item --message=MESSAGE

Prepends the MESSAGE to the VCS log message that L<Pinto> generates.
This is only relevant if you are using a VCS-based storage mechanism
for L<Pinto>.

=item --nocommit

Prevents L<Pinto> from committing changes in the repository to the VCS
after the operation.  This is only relevant if you are
using a VCS-based storage mechanism.  Beware this will leave your
working copy out of sync with the VCS.  It is up to you to then commit
or rollback the changes using your VCS tools directly.  Pinto will not
commit old changes that were left from a previous operation.

=item --noinit

Prevents L<Pinto> from pulling/updating the repository from the VCS
before the operation.  This is only relevant if you are using a
VCS-based storage mechanism.  This can speed up operations
considerably, but should only be used if you *know* that your working
copy is up-to-date and you are going to be the only actor touching the
Pinto repository within the VCS.

=item --tag=NAME

Instructs L<Pinto> to tag the head revision of the repository at NAME.
This is only relevant if you are using a VCS-based storage mechanism.
The syntax of the NAME depends on the type of VCS you are using.

=back

=cut
