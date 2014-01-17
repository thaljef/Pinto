package App::Pinto::Command::roots;

# ABSTRACT: show the roots of a stack

use strict;
use warnings;

use Pinto::Util qw(interpolate);

#-----------------------------------------------------------------------------

use base 'App::Pinto::Command';

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

sub command_names { return qw( roots ) }

#------------------------------------------------------------------------------

sub opt_spec {
    my ( $self, $app ) = @_;

    return (
        [ 'format=s'          => 'Format specification (See POD for details)' ],
        [ 'stack|s=s'         => 'Show roots of this stack' ],
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

    return 1;
}

#------------------------------------------------------------------------------

1;

__END__

=head1 SYNOPSIS

  pinto --root=REPOSITORY_ROOT roots [OPTIONS]

=head1 DESCRIPTION

!! THIS COMMAND IS EXPERIMENTAL !!

This command lists the distributions that are the roots of the dependency
tree that includes all the distributions in the stack.  In other words, it 
tells you which distributions or packages you would need to install from 
this stack to get all the other distribution in the stack.

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

=item --format FORMAT_SPECIFICATION

Format of the output of each record using C<printf>-style placeholders.  Valid 
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
  %M             Distribution main module
  %h             Distribution index path [1]
  %H             Distribution physical path [2]
  %s             Distribution origin:            (l) = local,     (f) = foreign
  %S             Distribution source
  %d             Distribution name
  %D             Distribution name-version
  %V             Distribution version
  %u             Distribution URI
  %%             A literal '%'


  [1]: The index path is always a Unix-style path fragment, as it
       appears in the 02packages.details.txt index file.

  [2]: The physical path is always in the native style for this OS,
       and is relative to the root directory of the repository.

You can also specify the minimum field widths and left or right
justification, using the usual notation.  The default format is C<%a/%f>.

=item --stack NAME

=item -s NAME

List the roots of the stack with the given NAME.  Defaults to the
name of whichever stack is currently marked as the default stack.  Use
the L<stacks|App::Pinto::Command::stacks> command to see the
stacks in the repository.

=back

=head1 EXAMPLES

Install all modules in the stack in one shot:

  pinto -r /myrepo roots | cpanm --mirror-only --mirror file:///myrepo

Generate a basic F<cpanfile> that would install all modules in the stack:

  pinto -r /myrepo roots -f 'requires q{%M};' > cpanfile

=head1 CAVEATS

This list of roots produced by this command is not always correct.  Many 
Perl distributions use dynamic configuration so you can't truly know 
what distributions need to be installed until you actually try and 
install them.  Pinto relies entirely on the static META files to determine
prerequisites.

But in most cases, this list is pretty accurate.  When it is wrong, it
typically includes too many distributions rather than too few.  At best,
this will have no impact because your installer will have already installed
them as prerequisites.  At worst, you may be installing a distribution that
you don't really need.

=cut
