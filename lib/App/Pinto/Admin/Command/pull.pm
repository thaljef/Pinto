# ABSTRACT: pull distributions from upstream repositories

package App::Pinto::Admin::Command::pull;

use strict;
use warnings;

use Pinto::Util;

#------------------------------------------------------------------------------

use base 'App::Pinto::Admin::Command';

#------------------------------------------------------------------------------

# VERSION

#-----------------------------------------------------------------------------

sub command_names { return qw( pull ) }

#-----------------------------------------------------------------------------

sub opt_spec {
    my ($self, $app) = @_;

    return (
        [ 'message|m=s' => 'Message for the revision log' ],
        [ 'norecurse'   => 'Do not recursively pull prereqs' ],
        [ 'pin'         => 'Pin all added packages to the stack' ],
        [ 'stack|s=s'   => 'Put packages into this stack' ],
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

  pinto-admin --root=/some/dir pull [OPTIONS] TARGET ...
  pinto-admin --root=/some/dir pull [OPTIONS] < LIST_OF_TARGETS

=head1 DESCRIPTION

This command locates a package in your upstream repositories and then
pulls the distribution providing that package into your repository.
Then it recursively locates and pulls all the distributions that are
necessary to satisfy its prerequisites.  You can also request to
directly pull a particular distribution.

When locating packages, Pinto first looks at the the packages that
already exist in the local repository, then Pinto looks at the
packages that are available available on the upstream repositories.
At present, Pinto takes the *first* package it can find that satisfies
the prerequisite.  In the future, you may be able to direct Pinto to
instead choose the *latest* package that satisfies the prerequisite.
(NOT SURE THOSE LAST TWO STATEMENTS ARE TRUE).

Pulled distributions will be assigned to their original author
(compare this to the C<add> command which makes B<you> the author of
the distribution).  Also, packages provided by pulled distributions
are still considered foreign, so locally added packages will always
override ones that you pulled, even if the pulled package has a
higher version.

=head1 COMMAND ARGUMENTS

Arguments are the targets that you want to pull.  Targets can be
specified as packages (with or without a minimum version number) or
as particular distributions.  For example:

  Foo::Bar                                 # Pulls any version of Foo::Bar
  Foo::Bar-1.2                             # Pulls Foo::Bar 1.2 or higher
  SHAKESPEARE/King-Lear-1.2.tar.gz         # Pulls a specific distribuion
  SHAKESPEARE/tragedies/Hamlet-4.2.tar.gz  # Ditto, but from a subdirectory

You can also pipe arguments to this command over STDIN.  In that case,
blank lines and lines that look like comments (i.e. starting with "#"
or ';') will be ignored.

=head1 COMMAND OPTIONS

=over 4

=item --message=MESSAGE

Use the given MESSAGE as the revision log message.

=item --norecurse

Prevents L<Pinto> from recursively pulling any distributions required
to satisfy prerequisites.

=item --stack=NAME

Instructs L<Pinto> to place all the packages within the distribution
into the stack with the given NAME.  All packages are always placed
in the C<default> stack as well.

=back

=cut
