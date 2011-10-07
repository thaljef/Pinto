package App::Pinto::Admin::Command::reindex;

# ABSTRACT: reindex distributions in the repository

use strict;
use warnings;

use Pinto::Util;

#-----------------------------------------------------------------------------

use base 'App::Pinto::Admin::Command';

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

sub opt_spec {
    my ($self, $app) = @_;

    return (
        [ 'author=s'    => 'Your (alphanumeric) author ID' ],
        [ 'message|m=s' => 'Prepend a message to the VCS log' ],
        [ 'nocommit'    => 'Do not commit changes to VCS' ],
        [ 'noinit'      => 'Do not pull/update from VCS' ],
        [ 'tag=s'       => 'Specify a VCS tag name' ],
    );
}

#------------------------------------------------------------------------------

sub usage_desc {
    my ($self) = @_;

    my ($command) = $self->command_names();

 my $usage =  <<"END_USAGE";
%c --repos=PATH $command [OPTIONS] DISTRIBUTION_PATH ...
%c --repos=PATH $command [OPTIONS] < LIST_OF_DISTRIBUTION_PATHS
END_USAGE

    chomp $usage;
    return $usage;
}


#------------------------------------------------------------------------------

sub execute {
    my ($self, $opts, $args) = @_;

    my @args = @{$args} ? @{$args} : Pinto::Util::args_from_fh(\*STDIN);
    return 0 if not @args;

    $self->pinto->new_batch( %{$opts} );
    $self->pinto->add_action('Reindex', %{$opts}, path => $_) for @args;
    my $result = $self->pinto->run_actions();

    return $result->is_success() ? 0 : 1;
}

#------------------------------------------------------------------------------

1;

__END__

=head1 SYNOPSIS

  pinto-admin --repos=/some/dir reindex [OPTIONS] DISTRIBUTION_PATH ...
  pinto-admin --repos=/some/dir reindex [OPTIONS] < LIST_OF_DISTRIBUTION_PATHS

=head1 DESCRIPTION

This command examines existing distribution archives in your
repository and reindexes the packages they contain.  L<Pinto> does not
guarantee that it will index distributions the same way that PAUSE
does.  So if you reindex a foreign distribution that came from a CPAN
mirror, you may not get the same result (especially for very old or
unusually packaged distributions).  However, the results are usually
good enough for most purposes.  See the L<Pinto::Manual> for details
on how Pinto indexes packages.

=head1 COMMAND ARGUMENTS

Arguments to this command are the paths to the distribution archives
you wish to reindex.  The precise archive that will be reindexed depends
on who you are.  So if you are C<JOE> and you ask to reindex
C<Foo-1.0.tar.gz> then you are really asking to reindex
F<J/JO/JOE/Foo-1.0.tar.gz>.

To reindex an archive that is owned by another author, use the
C<--author> option to change your identity.  Or you can just
explicitly specify the full path of the archive (note that paths are
always expressed with forward slashes).  So the following two examples
are equivalent:

  $> pinto-admin --repos=/some/dir reindex --author=SUSAN Foo-1.0.tar.gz
  $> pinto-admin --repos=/some/dir reindex S/SU/SUSAN/Foo-1.0.tar.gz

You can also pipe arguments to this command over STDIN.  In that case,
blank lines and lines that look like comments (i.e. starting with "#"
or ";") will be ignored.

=head1 COMMAND OPTIONS

=over 4

=item --author=NAME

Sets your identity as a distribution author.  The NAME can only be
alphanumeric characters only (no spaces) and will be forced to
uppercase.  The default is your username.

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
