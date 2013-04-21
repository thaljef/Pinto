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
    my ($self, $app) = @_;

    return (
        [ 'author|A=s'        => 'Limit to distributions by author' ],
        [ 'distributions|D=s' => 'Limit to matching distribution names' ],
        [ 'packages|P=s'      => 'Limit to matching package names' ],
        [ 'pinned!'           => 'Limit to pinned packages (negatable)' ],
        [ 'format=s'          => 'Format specification (See POD for details)' ],
        [ 'stack|s=s'         => 'List contents of this stack' ],
    );
}

#------------------------------------------------------------------------------

sub validate_args {
    my ($self, $opts, $args) = @_;

    $self->usage_error('Multiple arguments are not allowed')
        if @{ $args } > 1;

    $opts->{format} = interpolate( $opts->{format} )
        if exists $opts->{format};

    $opts->{stack} = $args->[0]
        if $args->[0];

    return 1;
}

#------------------------------------------------------------------------------

1;

__END__

=head1 SYNOPSIS

  pinto --root=REPOSITORY_ROOT list [OPTIONS]

=head1 DESCRIPTION

This command lists the distributions and packages that are registered
on a stack.  You can format the output to see the specific bits of 
information that you want.

For a large repository, it can take a long time to list everything.
So consider using the C<--packages> or C<--distributions> options
to narrow the scope.  

=head1 COMMAND ARGUMENTS

As an alternative to the C<--stack> option, you can also specify the
stack as an argument. So the following examples are equivalent:

  pinto --root REPOSITORY_ROOT list --stack dev
  pinto --root REPOSITORY_ROOT list dev

A stack specified as an argument in this fashion will override any
stack specified with the C<--stack> option.  If a stack is not
specified by neither argument nor option, then it defaults to the
stack that is currently marked as the default stack.

=head1 COMMAND OPTIONS

=over 4

=item --author AUTHOR

=item -A AUTHOR

Limit the listing to records where the distribution author is AUTHOR.
Note this is an exact match, not a pattern match.  However, it is
not case sensitive.

=item --distributions PATTERN

=item -D PATTERN

Limit the listing to records where the distribution archive name
matches C<PATTERN>.  Note that C<PATTERN> is just a plain string, not
a regular expression.  The C<PATTERN> will match if it appears
anywhere in the distribution archive name.

=item --format FORMAT_SPECIFICATION

Format of the output using C<printf>-style placeholders.  Valid
placeholders are:

  Placeholder    Meaning
  -----------------------------------------------------------------------------
  %p             Package name
  %P             Package name-version
  %v             Package version
  %y             Pin status:                     (!) = is pinned
  %a             Distribution author
  %f             Distribution archive filename
  %m             Distribution maturity:          (d) = developer, (r) = release
  %h             Distribution index path [1]
  %H             Distribution physical path [2]
  %s             Distribution origin:            (l) = local,     (f) = foreign
  %S             Distribution source
  %d             Distribution name
  %D             Distribution name-version
  %V             Distribution version
  %u             Distribution url
  %%             A literal '%'


  [1]: The index path is always a Unix-style path fragment, as it
       appears in the 02packages.details.txt index file.

  [2]: The physical path is always in the native style for this OS,
       and is relative to the root directory of the repository.

You can also specify the minimum field widths and left or right
justification, using the usual notation.  For example, the default
format looks something like this:

  %m%s %-38n %12v %a/%f\n

=item --packages PATTERN

=item -P PATTERN

Limit the listing to records where the package name matches
C<PATTERN>.  Note that C<PATTERN> is just a plain string, not a
regular expression.  The C<PATTERN> will match if it appears anywhere
in the package name.

=item --pinned

Limit the listing to records for packages that are pinned.

=item --stack NAME

=item -s NAME

List the contents of the stack with the given NAME.  Defaults to the
name of whichever stack is currently marked as the default stack.  Use
the L<stacks|App::Pinto::Command::stacks> command to see the
stacks in the repository.

=back

=cut
