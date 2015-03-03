# ABSTRACT: unpack and open distributions with your shell

package App::Pinto::Command::look;

use strict;
use warnings;

use Pinto::Util qw(is_remote_repo);
use MRO::Compat; # for Perl older than 5.9.5

#------------------------------------------------------------------------------

use base 'App::Pinto::Command';

#------------------------------------------------------------------------------

# VERSION

#-----------------------------------------------------------------------------

sub opt_spec {
    my ( $self, $app ) = @_;

    return (
        [ 'shell=s' => 'The path to the shell command to use' ],
    );
}

#------------------------------------------------------------------------------

sub validate_args {
    my ( $self, $opts, $args ) = @_;

    $self->usage_error('Requires at least one target')
        unless @{$args};

    return 1;
}

sub args_attribute { return 'targets' }

#------------------------------------------------------------------------------

sub args_from_stdin { return 1 }

#------------------------------------------------------------------------------

sub execute {
    my ( $self, $opts, $args ) = @_;

    my $global_opts = $self->app->global_options;

    die "Cannot look into remote repositories (yet)\n"
        if is_remote_repo( $global_opts->{root} );

    return $self->SUPER::execute($opts, $args);
};

#------------------------------------------------------------------------------

1;

__END__


=head1 SYNOPSIS

  pinto --root=REPOSITORY_ROOT look [OPTIONS] TARGET ...

=head1 DESCRIPTION

Unpack one or more distributions and explore its contents with your shell.
This is handy if you want to manually inspect a distribution before use.  At
present, this command only works with local repositories and distributions
that are already in the repository.

=head1 COMMAND ARGUMENTS

Arguments are the targets you wish to look at.  Targets can be
specified as packages or distributions, such as:

  Some::Package
  Some::Other::Package

  AUTHOR/Some-Dist-1.2.tar.gz
  AUTHOR/Some-Other-Dist-1.3.zip

You can also pipe arguments to this command over STDIN.  In that case,
blank lines and lines that look like comments (i.e. starting with "#"
or ';') will be ignored.

=head1 COMMAND OPTIONS

=over 4

=item --shell=NAME

The path to the shell to use.  Defaults to the environment variable
C<SHELL> or to C<COMSPEC> on Windows.

=back

=cut
