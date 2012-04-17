package App::Pinto::Admin::Command::import;

# ABSTRACT: get selected distributions from a remote repository

use strict;
use warnings;

use Pinto::Util;

#------------------------------------------------------------------------------

use base 'App::Pinto::Admin::Command';

#------------------------------------------------------------------------------

# VERSION

#-----------------------------------------------------------------------------

sub command_names { return qw( import ) }

#-----------------------------------------------------------------------------

sub opt_spec {
    my ($self, $app) = @_;

    return (
        [ 'message|m=s' => 'Prepend a message to the VCS log' ],
        [ 'nocommit'    => 'Do not commit changes to VCS' ],
        [ 'noinit'      => 'Do not pull/update from VCS' ],
        [ 'norecurse'   => 'Do not recursively import prereqs' ],
        [ 'stack|s=s'   => 'Put packages into this stack' ],
        [ 'tag=s'       => 'Specify a VCS tag name' ],
    );
}

#------------------------------------------------------------------------------

sub usage_desc {
    my ($self) = @_;

    my ($command) = $self->command_names();

    my $usage =  <<"END_USAGE";
%c --root=PATH $command [OPTIONS] TARGET ...
%c --root=PATH $command [OPTIONS] < LIST_OF_TARGETS
END_USAGE

    chomp $usage;
    return $usage;
}

#------------------------------------------------------------------------------

sub execute {
    my ($self, $opts, $args) = @_;

    my @args = @{$args} ? @{$args} : Pinto::Util::args_from_fh(\*STDIN);
    return 0 if not @args;

    $self->pinto->new_batch(%{$opts});
    $self->pinto->add_action($self->action_name, %{$opts}, target => $_) for @args;
    my $result = $self->pinto->run_actions();

    return $result->is_success() ? 0 : 1;
}

#------------------------------------------------------------------------------

1;

__END__

=for stopwords norecurse

=head1 SYNOPSIS

  pinto-admin --root=/some/dir import [OPTIONS] TARGET ...
  pinto-admin --root=/some/dir import [OPTIONS] < LIST_OF_TARGETS

=head1 DESCRIPTION

This command locates a package in your upstream repositories and then
imports the distribution providing that package into your repository.
Then it recursively locates and imports all the distributions that are
necessary to satisfy its prerequisites.  You can also request to
directly import a particular distribution.

When locating packages, Pinto first looks at the the packages that
already exist in the local repository, then Pinto looks at the
packages that are available available on the upstream repositories.
At present, Pinto takes the *first* package it can find that satisfies
the prerequisite.  In the future, you may be able to direct Pinto to
instead choose the *latest* package that satisfies the prerequisite.
(NOT SURE THOSE LAST TWO STATEMENTS ARE TRUE).

Imported distributions will be assigned to their original author
(compare this to the C<add> command which makes B<you> the author of
the distribution).  Also, packages provided by imported distributions
are still considered foreign, so locally added packages will always
override ones that you imported, even if the imported package has a
higher version.

=head1 COMMAND ARGUMENTS

Arguments are the targets that you want to import.  Targets can be
specified as packages (with or without a minimum version number) or
as particular distributions.  For example:

  Foo::Bar                                 # Imports any version of Foo::Bar
  Foo::Bar-1.2                             # Imports Foo::Bar 1.2 or higher
  SHAKESPEARE/King-Lear-1.2.tar.gz         # Imports a specific distribuion
  SHAKESPEARE/tragedies/Hamlet-4.2.tar.gz  # Ditto, but from a subdirectory

You can also pipe arguments to this command over STDIN.  In that case,
blank lines and lines that look like comments (i.e. starting with "#"
or ';') will be ignored.

=head1 COMMAND OPTIONS

=over 4

=item --message=MESSAGE

Prepends the MESSAGE to the VCS log message that L<Pinto> generates.
This is only relevant if you are using a VCS-based storage mechanism
for L<Pinto>.

=item --nocommit

Prevents L<Pinto> from committing changes in the repository to the VCS
after the operation.  This is only relevant if you are using a
VCS-based storage mechanism.  Beware this will leave your working copy
out of sync with the VCS.  It is up to you to then commit or rollback
the changes using your VCS tools directly.  Pinto will not commit old
changes that were left from a previous operation.

=item --noinit

Prevents L<Pinto> from pulling/updating the repository from the VCS
before the operation.  This is only relevant if you are using a
VCS-based storage mechanism.  This can speed up operations
considerably, but should only be used if you *know* that your working
copy is up-to-date and you are going to be the only actor touching the
Pinto repository within the VCS.

=item --norecurse

Prevents L<Pinto> from recursively importing any distributions
required to satisfy prerequisites.

=item --stack=NAME

Instructs L<Pinto> to place all the packages within the distribution
into the stack with the given NAME.  All packages are always placed
in the C<default> stack as well.

=item --tag=NAME

Instructs L<Pinto> to tag the head revision of the repository at NAME.
This is only relevant if you are using a VCS-based storage mechanism.
The syntax of the NAME depends on the type of VCS you are using.

=back

=cut
