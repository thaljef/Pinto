package App::Pinto::Admin::Command::rebuild;

# ABSTRACT: rebuild the repository index

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

    return (
        [ 'message|m=s' => 'Prepend a message to the VCS log' ],
        [ 'nocommit'    => 'Do not commit changes to VCS' ],
        [ 'noinit'      => 'Do not pull/update from VCS' ],
        [ 'recompute'   => 'Also recompute latest versions' ],
        [ 'tag=s'       => 'Specify a VCS tag name' ],
    );
}

#------------------------------------------------------------------------------

sub validate_args {
    my ($self, $opts, $args) = @_;

    $self->usage_error('Arguments are not allowed') if @{ $args };

    return 1;
}

#------------------------------------------------------------------------------

sub execute {
    my ($self, $opts, $args) = @_;

    $self->prompt_for_confirmation()
        if IO::Interactive::is_interactive();

    $self->pinto->new_batch( %{$opts} );
    $self->pinto->add_action('Rebuild', %{$opts});
    my $result = $self->pinto->run_actions();

    return $result->is_success() ? 0 : 1;

}

#------------------------------------------------------------------------------

sub prompt_for_confirmation {
    my ($self) = @_;

    print <<'END_MESSAGE';
Rebuilding the 02packages.details file may cause its contents to change.
This means that users pulling distributions from your repository could
start getting different results after you rebuild.  Once the
02packages.details file has been rebuilt, the only way to restore the
old version is to roll back your VCS (if that is applicable).

END_MESSAGE

    my $answer = '';

    until ($answer =~ m/^[yn]$/ix) {
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

  pinto-admin --repos=/some/dir rebuild [OPTIONS]

=head1 DESCRIPTION

In the event your index file becomes corrupt or goes missing, you can
use this command to rebuild it.  Note this is not the same as
re-indexing all your distributions.  Rebuilding the index simply means
regenerating the index file from the information that L<Pinto> already
has about your distributions.

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

=item --recompute

Instructs L<Pinto> to also recompute what it thinks is the 'latest'
version of each package in the repository.  This is useful if you've
upgraded to a newer version of Pinto that has different logic for
determining the 'latest' version.  Beware that this may change your
index (hopefully for the better).

=item --tag=NAME

Instructs L<Pinto> to tag the head revision of the repository at NAME.
This is only relevant if you are using a VCS-based storage mechanism.
The syntax of the NAME depends on the type of VCS you are using.

=back

=cut
