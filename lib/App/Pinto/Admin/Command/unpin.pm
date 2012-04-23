package App::Pinto::Admin::Command::unpin;

# ABSTRACT: free a package that has been pinned

use strict;
use warnings;

use Pinto::Util;

#------------------------------------------------------------------------------

use base 'App::Pinto::Admin::Command';

#------------------------------------------------------------------------------

# VERSION

#-----------------------------------------------------------------------------

sub opt_spec {
    my ($self, $app) = @_;

    return (
        [ 'message|m=s' => 'Message for the revision log' ],
    );
}

#------------------------------------------------------------------------------

sub usage_desc {
    my ($self) = @_;

    my ($command) = $self->command_names();

    my $usage =  <<"END_USAGE";
%c --root=PATH $command [OPTIONS] STACK_NAME PACKAGE_NAME ...
%c --root=PATH $command [OPTIONS] STACK_NAME < LIST_OF_PACKAGE_NAMES
END_USAGE

    chomp $usage;
    return $usage;
}

#------------------------------------------------------------------------------

sub validate_args {
    my ($self, $opts, $args) = @_;

    $self->usage_error("Must specify a STACK_NAME and at least one PACKAGE_NAME")
        if @{ $args } < 2;

    return 1;

}

#------------------------------------------------------------------------------

sub execute {
    my ($self, $opts, $args) = @_;

    my $stack_name = shift @{ $args };

    my @package_names = @{$args} ? @{$args} : Pinto::Util::args_from_fh(\*STDIN);
    return 0 if not @package_names;

    $self->pinto->new_batch( %{$opts} );

    for my $package_name (@package_names) {
        $self->pinto->add_action($self->action_name(), %{$opts}, package => $package_name,
                                                                 stack   => $stack_name );
    }

    my $result = $self->pinto->run_actions();

    return $result->is_success() ? 0 : 1;
}

#------------------------------------------------------------------------------

1;

__END__


=head1 SYNOPSIS

  pinto-admin --root=/some/dir unpin [OPTIONS] STACK_NAME PACKAGE_NAME ...
  pinto-admin --root=/some/dir unpin [OPTIONS] STACK_NAME < LIST_OF_PACKAGE_NAMES

=head1 DESCRIPTION

This command unpins a package in the stack, so that the package can be
merged into another stack with a newer version of the package, or the
package can be upgraded to a newer version within this stack.

=head1 COMMAND ARGUMENTS

Arguments are the names of the packages you wish to unpin.

You can also pipe arguments to this command over STDIN.  In that case,
blank lines and lines that look like comments (i.e. starting with "#"
or ';') will be ignored.

=head1 COMMAND OPTIONS

=over 4

=item --message=MESSAGE

Use the given MESSAGE as the revision log message

=back

=cut
