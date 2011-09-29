package App::Pinto::Admin::Command::remove;

# ABSTRACT: remove distributions from the repository

use strict;
use warnings;

use Pinto::Util;

#-----------------------------------------------------------------------------

use base 'App::Pinto::Admin::Command';

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

sub command_names { return qw( remove rm delete del ) }

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
%c --repos=PATH $command [OPTIONS] DISTRIBUTION_NAME ...
%c --repos=PATH $command [OPTIONS] < LIST_OF_DISTRIBUTION_NAMES
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
    $self->pinto->add_action('Remove', %{$opts}, dist_name => $_) for @args;
    my $result = $self->pinto->run_actions();

    return $result->is_success() ? 0 : 1;
}

#------------------------------------------------------------------------------

1;

__END__

=head1 SYNOPSIS

  pinto-admin --repos=/some/dir remove [OPTIONS] DISTRIBUTION_NAME ...
  pinto-admin --repos=/some/dir remove [OPTIONS] < LIST_OF_DISTRIBUTION_NAMES

=head1 DESCRIPTION

This command removes a distribution and all its packages from the
repository and recomputes the 'latest' version of the packages that
were in that distribution.

=head1 COMMAND ARGUMENTS

Arguments to this command are the names of the distributions you wish
to remove.  You must specify the complete distribution name, including
version number and extension.  The precise identity of the
distribution that will be removed depends on who you are.  So if you
are C<JOE> and you ask to remove C<Foo-1.0.tar.gz> then you are really
asking to remove F<J/JO/JOE/Foo-1.0.tar.gz>.

To remove a distribution that was added by another author, use the
C<--author> option to change who you are.  Or you can just
explicitly specify the full identity of the distribution.  So the
following two examples are equivalent:

  $> pinto-admin --repos=/some/dir remove --author=SUSAN Foo-1.0.tar.gz
  $> pinto-admin --repos=/some/dir remove S/SU/SUSAN/Foo-1.0.tar.gz

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

=head1 DISCUSSION

Local packages are always considered 'later' then any foreign package
with the same name, even if the foreign package has a higher version
number.  So a foreign package will not become 'latest' until all
versions of the local package with that name have been removed.

Removing the latest version of local package generally works as you
would expect.  That is, the package with the next highest version (if
it exists) will take its place in the 02packages.details file.  But
when removing the latest version of a foreign package, the next
'latest' version may not alway appear in the 02packages.details file,
or it may not be the version you were expecting.

This is because Pinto does not index foreign distributions so it only
knows about the packages listed in the foreign index, which may not
actually represent all the packages in that distribution.  Moreover,
the completeness of the history of a foreign package depends on how
often you update your repository.  So if you update infrequently,
there may be large gaps between the package versions that your Pinto
repository knows about.

=cut
