# ABSTRACT: join two stack histories together

package App::Pinto::Command::merge;

use strict;
use warnings;

#-----------------------------------------------------------------------------

use base 'App::Pinto::Command';

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

sub command_names { return qw(merge) }

#------------------------------------------------------------------------------

sub opt_spec {
    my ( $self, $app ) = @_;

    return ();
}

#------------------------------------------------------------------------------

sub validate_args {
    my ( $self, $opts, $args ) = @_;

    my $arg_count = @{$args};

    $self->usage_error("Must specify a stack to merge from")
      if not $arg_count;

    $self->usage_error("Too many arguments")
      if $arg_count > 2;

    $opts->{stack} = $args->[0];
    $opts->{into_stack} = $args->[1];

    return 1;
}

#------------------------------------------------------------------------------
1;

__END__

=pod

=head1 SYNOPSIS

  pinto --root=REPOSITORY_ROOT merge [OPTIONS] STACK [INTO_STACK]

=head1 DESCRIPTION

!! THIS COMMAND IS EXPERIMENTAL !!

This command joins the history of one stack with another.  At present, it is
only capable of doing a "fast-forward" merge when the head of STACK is a
direct descendant of the head of INTO_STACK.

=head1 COMMAND ARGUMENTS

The first mandatory argument is the name of the stack to merge from.  The
second optional argument is the name of the stack to merge to.  If the second
argument is not specified, it defaults to whichever stack is currently marked
as the default.  Here are some examples:

  pinto ... merge dev               # Merge the "dev" stack into the default stack
  pinto ... merge dev prod          # Merge the "dev" stack into the "prod" stack

=head1 COMMAND OPTIONS

=over 4

=item --dry-run

Go through all the motions, but do not actually commit any changes to the
repository.  At the conclusion, a diff showing the changes that would have
been made will be displayed.  Use this option to see how upgrades would
potentially impact the stack.


=item --message=TEXT

=item -m TEXT

Use TEXT as the revision history log message.  If you do not use the
C<--message> option or the C<--use-default-message> option, then you will be
prompted to enter the message via your text editor.  Use the C<PINTO_EDITOR>
or C<EDITOR> or C<VISUAL> environment variables to control which editor is
used.  A log message is not required whenever the C<--dry-run> option is set,
or if the action did not yield any changes to the repository.


=item --use-default-message

=item -M

Use the default value for the revision history log message.  Pinto will
generate a semi-informative log message just based on the command and its
arguments.  If you set an explicit message with C<--message>, the C<--use-
default-message> option will be silently ignored.

=back

=cut
