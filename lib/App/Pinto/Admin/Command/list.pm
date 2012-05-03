package App::Pinto::Admin::Command::list;

# ABSTRACT: show the packages in a stack

use strict;
use warnings;

#-----------------------------------------------------------------------------

use base 'App::Pinto::Admin::Command';

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

sub command_names { return qw( list ls ) }

#------------------------------------------------------------------------------

sub opt_spec {
    my ($self, $app) = @_;

    return (
        [ 'distributions|D=s' => 'Limit to matching distribution paths' ],
        [ 'packages|P=s'      => 'Limit to matching package names' ],
        [ 'pinned!'           => 'Limit to pinned packages (negatable)' ],
        [ 'format=s'          => 'Format specification (See POD for details)' ],
        [ 'stack|s=s'         => 'List a stack other than the default' ],
    );
}

#------------------------------------------------------------------------------

sub validate_args {
    my ($self, $opts, $args) = @_;

    $self->usage_error('Multiple arguments are not allowed')
        if @{ $args } > 1;

    $self->usage_error('Cannot specify packages and distributions together')
        if $opts->{packages} and $opts->{distributions};

    $opts->{format} = eval qq{"$opts->{format}"} ## no critic qw(StringyEval)
        if $opts->{format};

    $opts->{stack} = $args->[0]
        if $args->[0];

    return 1;
}

#------------------------------------------------------------------------------

1;

__END__

=head1 SYNOPSIS

  pinto-admin --root=/some/dir list [OPTIONS]

=head1 DESCRIPTION

This command lists the distributions and packages that are registered
to a stack within the repository.  You can format the output to see
the specific bits of information that you want.

For a large repository, it can take fair amount of time to list
everything.  You might consider using the C<--packages> or
C<--distributions> options to narrow the scope.  If you need even more
precise filtering, consider running the output through C<grep>.

=head1 COMMAND ARGUMENTS

As an alternative to the C<--stack> option, you can also specify the
stack as an argument. So the following examples are equivalent:

  pinto-admin --root /some/dir list --stack dev
  pinto-admin --root /some/dir list dev

A stack specified as an argument in this fashion will override any
stack specified with the C<--stack> option.

=head1 COMMAND OPTIONS

=over 4

=item -D=PATTERN

=item --distributions=PATTERN

Limit the listing to records where the distributions path matches
C<PATTERN>.  Note that C<PATTERN> is just a plain string, not a regular
expression.  The C<PATTERN> will match if it appears anywhere in the
distribution path.

=item --format=FORMAT_SPECIFICATION

Format of the output using C<printf>-style placeholders.  Valid
placeholders are:

  Placeholder    Meaning
  -----------------------------------------------------------------------------
  %n             Package name
  %N             Package name-version
  %v             Package version
  %y             Pin status:                     (+) = is pinned
  %m             Distribution maturity:          (d) = developer, (r) = release
  %p             Distribution index path [1]
  %P             Distribution physical path [2]
  %s             Distribution origin:            (l) = local, (f) = foreign
  %S             Distribution source repository
  %a             Distribution author
  %d             Distribution name
  %D             Distribution name-version
  %w             Distribution version
  %u             Distribution url
  %k             Stack name
  %e             Stack description
  %M             Stack status                   (*) = is master
  %U             Stack last-modified-time
  %j             Stack last-modified-user
  %%             A literal '%'


  [1]: The index path is always a Unix-style path fragment, as it
       appears in the 02packages.details.txt index file.

  [2]: The physical path is always in the native style for this OS,
       and is relative to the root directory of the repository.

You can also specify the minimum field widths and left or right
justification, using the usual notation.  For example, this is what
the default format looks like.

  %m%s %-38n %v %p\n

=item -P=PATTERN

=item --packages=PATTERN

Limit the listing to records where the package name matches
C<PATTERN>.  Note that C<PATTERN> is just a plain string, not a
regular expression.  The C<PATTERN> will match if it appears anywhere
in the package name.

=item --pinned

Limit the listing to records for packages that are pinned.

=item --stack=NAME

List the contents of the stack with the given NAME.  Defaults to the
name of whichever stack is currently marked as the master stack.  Use
the C<stack list> command to see the stacks in the repository.

If the stack name is '@' then the contents of all stacks will be
listed.  And unless an explicit C<--format> was given, the listing
will include the name of the stack on each record.

=back

=cut
