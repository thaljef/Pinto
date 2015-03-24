package App::Pinto::Command::list;

# ABSTRACT: show the packages in a stack

use strict;
use warnings;

use Pinto::Util qw(interpolate);

#-----------------------------------------------------------------------------

use base 'App::Pinto::Command';

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

sub command_names { return qw( list ls ) }

#------------------------------------------------------------------------------

sub opt_spec {
    my ( $self, $app ) = @_;

    return (
        [ 'all|a'             => 'List everything in the repository'],
        [ 'authors|A=s'       => 'Limit to matching author identities' ],
        [ 'distributions|D=s' => 'Limit to matching distribution names' ],
        [ 'packages|P=s'      => 'Limit to matching package names' ],
        [ 'pinned!'           => 'Limit to pinned packages (negatable)' ],
        [ 'format=s'          => 'Format specification (See POD for details)' ],
        [ 'stack|s=s'         => 'List contents of this stack' ],
    );
}

#------------------------------------------------------------------------------

sub validate_args {
    my ( $self, $opts, $args ) = @_;

    $self->usage_error('Multiple arguments are not allowed')
        if @{$args} > 1;

    $opts->{format} = interpolate( $opts->{format} )
        if exists $opts->{format};

    $opts->{stack} = $args->[0]
        if $args->[0];

    $self->usage_error('Cannot specify a stack when using --all')
        if $opts->{stack} && $opts->{all};

    return 1;
}

#------------------------------------------------------------------------------

1;

__END__

=head1 SYNOPSIS

  pinto --root=REPOSITORY_ROOT list [OPTIONS]

=head1 DESCRIPTION

This command lists the packages that are currently registered on a particular
stack, or all the packages in the entire repository.  You can format the
output to see the specific bits of information that you want.

For a large repository, it can take a long time to list everything. So
consider using the C<--packages> or C<--distributions> options to narrow the
scope.

=head1 COMMAND ARGUMENTS

As an alternative to the C<--stack> option, you can also specify the stack as
an argument. So the following examples are equivalent:

  pinto --root REPOSITORY_ROOT list --stack dev
  pinto --root REPOSITORY_ROOT list dev

A stack specified as an argument in this fashion will override any stack
specified with the C<--stack> option.  If a stack is not specified by neither
argument nor option, then it defaults to the stack that is currently marked as
the default stack.

=head1 COMMAND OPTIONS

=over 4

=item --all

=item -a

List every package in every distribution that exists in the entire repository,
including distributions that are not currently registered on any stack.  When
the C<--all> option is used, then the stack argument and C<--stack> option are
not allowed.  Also note the pin status is indeterminable when using the C<--all>
option so it always appears as C<?> (see the C<--format> option below for more
details about that).


=item --authors=PATTERN

=item -A PATTERN

Limit the listing to records where the distribution's author identity matches
C<PATTERN>.  The C<PATTERN> will be interpreted as a case-insensitive regular
expression.  Take care to use quotes if your C<PATTERN> contains any special
shell metacharacters.


=item --distributions=PATTERN

=item -D PATTERN

Limit the listing to records where the distribution archive name matches
C<PATTERN>.  The C<PATTERN> will be interpreted as a case-sensitive regular
expression.  Take care to use quotes if your C<PATTERN> contains any special
shell metacharacters.

=item --format FORMAT_SPECIFICATION

Format of the output using C<printf>-style placeholders.  Valid placeholders
are:

  Placeholder    Meaning
  -----------------------------------------------------------------------------
  %p             Package name
  %P             Package name-version
  %v             Package version
  %x             Package can be indexed:         (x) = true,      (-) = false
  %M             Package is the main module:     (m) = true,      (-) = false
  %y             Package is pinned:              (!) = true,      (-) = false
  %a             Distribution author
  %f             Distribution archive filename
  %m             Distribution maturity:          (d) = developer, (r) = release
  %h             Distribution index path [1]
  %H             Distribution physical path [2]
  %s             Distribution origin:            (l) = local,     (f) = foreign
  %S             Distribution source URL
  %d             Distribution name
  %D             Distribution name-version
  %V             Distribution version
  %u             Distribution URI
  %%             A literal '%'


  [1]: The index path is always a Unix-style path fragment, as it
       appears in the 02packages.details.txt index file.

  [2]: The physical path is always in the native style for this OS,
       and is relative to the root directory of the repository.

You can also specify the minimum field widths and left or right justification,
using the usual notation.  For example, the default format looks something
like this:

  [%m%s%y] %-40p %12v %a/%f

When using the C<--all> option, the pin status is indeterminable so it always
appears as C<?>.  Also, the indexable status is shown.  So the default format
looks something like this instead:

  [%m%s?%x] %-40p %12v %a/%f

=item --packages=PATTERN

=item -P PATTERN

Limit the listing to records where the package name matches C<PATTERN>.  The
C<PATTERN> will be interpreted as a case-sensitive regular expression.  Take
care to use quotes if your C<PATTERN> contains any special shell
metacharacters.


=item --pinned

Limit the listing to records for packages that are pinned.  This option has
no effect when using the C<--all> option.

=item --stack=NAME

=item -s NAME

List the contents of the stack with the given NAME.  Defaults to the name of
whichever stack is currently marked as the default stack.  Use the
L<stacks|App::Pinto::Command::stacks> command to see the stacks in the
repository.  This option cannot be used with the C<--all> option.

=back

=cut
