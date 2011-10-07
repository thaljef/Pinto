package App::Pinto::Admin::Command::update;

# ABSTRACT: get all the latest distributions from another repository

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
        [ 'message|m=s' => 'Prepend a message to the VCS log' ],
        [ 'nocommit'    => 'Do not commit changes to VCS' ],
        [ 'noinit'      => 'Do not pull/update from VCS' ],
        [ 'soft'        => 'Skip loading of remote indexes' ],
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

    $self->pinto->new_batch( %{$opts} );
    my @sources = $self->pinto->config->sources_list();
    $self->pinto->add_action('Update', %{$opts}, source => $_) for @sources;
    my $result = $self->pinto->run_actions();

    return $result->is_success() ? 0 : 1;
}

#------------------------------------------------------------------------------

1;

__END__

=head1 SYNOPSIS

  pinto-admin --repos=/some/dir update [OPTIONS]

=head1 DESCRIPTION

This command pulls the latest versions of all distributions from your
source repositories (usually one or more CPAN mirrors) into your local
repository.  The URLs of the source repositories are defined in the
configuration file at F<.pinto/config/pinto.ini> inside your
repository.

The update process happens in two steps: First, the index of the
source repository is loaded into the local L<Pinto> database.  Second,
every (new) distribution from that source is downloaded into the local
L<Pinto> repository.  These steps are repeated for each source
repository.

=head1 COMMAND ARGUMENTS

None

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

=item --soft

Directs L<Pinto> to not load the indexes of the source repositories
and just fetch the archives for any distributions that have already
been loaded.  This is helpful if the C<verify> command shows that some
foreign distribution archives have gone missing from your repository.

=item --tag=NAME

Instructs L<Pinto> to tag the head revision of the repository at NAME.
This is only relevant if you are using a VCS-based storage mechanism.
The syntax of the NAME depends on the type of VCS you are using.

=back

=cut
