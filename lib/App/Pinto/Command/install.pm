# ABSTRACT: install stuff from the repository

package App::Pinto::Command::install;

use strict;
use warnings;

#-----------------------------------------------------------------------------

use base 'App::Pinto::Command';

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

sub opt_spec {
    my ($self, $app) = @_;

    return (
        [ 'cpanm-exe|cpanm=s'       => 'Path to the cpanm executable'                 ],
        [ 'cpanm-options|o:s%'      => 'name=value pairs of cpanm options'            ],
        [ 'local-lib|l=s'           => 'install into a local lib directory'           ],
        [ 'local-lib-contained|L=s' => 'install into a contained local lib directory' ],
        [ 'message|m=s'             => 'Message to describe the change'               ],
        [ 'do-pull'                 => 'pull missing prereqs onto the stack first'    ],
        [ 'stack|s=s'               => 'Use the index for this stack'                 ],

    );
}

#------------------------------------------------------------------------------

sub validate_args {
    my ($self, $opts, $args) = @_;

    my $local_lib = delete $opts->{local_lib};
    $opts->{cpanm_options}->{'local-lib'} = $local_lib
        if $local_lib;

    my $local_lib_contained = delete $opts->{local_lib_contained};
    $opts->{cpanm_options}->{'local-lib-contained'} = $local_lib_contained
        if $local_lib_contained;

    $self->usage_error('--message is only useful with --pull')
        if $opts->{message} and not $opts->{pull};

    return 1;
}

#------------------------------------------------------------------------------

sub args_attribute { return 'targets' }

#------------------------------------------------------------------------------

sub args_from_stdin { return 1 }

#------------------------------------------------------------------------------
1;

__END__

=pod

=for stopwords 
exe 
cpanm

=head1 SYNOPSIS

  pinto --root=REPOSITORY_ROOT install [OPTIONS] TARGET...

=head1 DESCRIPTION

!! THIS COMMAND IS EXPERIMENTAL !!

Installs packages from the repository into your environment.  This
is just a thin wrapper around L<cpanm> that is wired to fetch
everything from the Pinto repository, rather than a public CPAN
mirror.

If the C<--pull> option is given, all prerequisites
(including the targets themselves) will be pulled onto the stack
before attempting to install them.  If any prerequisite cannot be
pulled because it does not exist or is blocked by a pin, then the
installation will not proceed.

=head1 COMMAND ARGUMENTS

Arguments are the things you want to install.  These can be package
names, distribution paths, URLs, local files, or directories.  Look at
the L<cpanm> documentation to see all the different ways of specifying
what to install.

You can also pipe arguments to this command over STDIN.  In that case,
blank lines and lines that look like comments (i.e. starting with "#"
or ';') will be ignored.

=head1 COMMAND OPTIONS

=over 4

=item --cpanm-exe PATH

=item --cpanm PATH

Sets the path to the L<cpanm> executable.  If not specified, the
C<PATH> will be searched for the executable.  At present, cpanm
version 1.500 or newer is required.

=item --cpanm-options NAME=VALUE

=item -o NAME=VALUE

These are options that you wish to pass to L<cpanm>.  Do not prefix
the option NAME with a '-'.  You can pass any option you like, but the
C<--mirror> and C<--mirror-only> options will always be set to point
to the Pinto repository.

=item --dry-run

Go through all the motions, but do not actually commit any changes to
the repository.  Use this option to see how the command would
potentially impact the stack.  This only has effect when using the
C<--pull> option.

=item --local-lib DIRECTORY

=item -l DIRECTORY

Shortcut for setting the C<--local-lib> option on L<cpanm>.  Same as
C<--cpanm-options local-lib=DIRECTORY> or C<-o l=DIRECTORY>.

=item --local-lib-contained DIRECTORY

=item -L DIRECTORY

Shortcut for setting the C<--local-lib-contained> option on L<cpanm>.
Same as C<--cpanm-options local-lib-containted=DIRECTORY> or C<-o
L=DIRECTORY>.

=item --message=TEXT

=item -m TEXT

Use TEXT as the revision history log message.  This is only relevant
if you also set the C<--pull> option.  If you do not use C<--message>
option, then you will be prompted to enter the message via your text
editor.  Use the C<EDITOR> or C<VISUAL> environment variables to
control which editor is used.  A log message is not required whenever
the C<--dry-run> option is set, or if the action did not yield any
changes to the repository.

=item --pull

Recursively pull prerequisite packages (or the targets themselves)
onto the stack before installing.  Without the C<--pull> option, all
prerequisites must already be on the stack.  See the
L<pull|App::Pinto::Command::pull> command to explicitly pull packages
onto a stack or the L<merge|App::Pinto::Command::merge> command to
merge packages from one stack to another.

=item --stack=NAME

=item -s NAME

Use the stack with the given NAME as the repository index.  When
used with the C<--pull> option, this also determines which stack
prerequisites will be pulled onto. Defaults to the name of whichever
stack is currently marked as the default stack.  Use the
L<stacks|App::Pinto::Command::stacks> command to see the stacks in
the repository.

=back

=head1 USING cpan OR cpanm DIRECTLY

On the surface, A Pinto repository looks like an ordinary CPAN repository,
so you can use any client to install modules.  All you have to do is "point" 
it at the URL of your Pinto repository.  Each client has a slightly different 
interface for setting the URL.

For L<cpanm>, use the C<--mirror> and C<--mirror-only> options like this:

  $> cpanm --mirror file:///path/to/repo --mirror-only Some::Package ...

For L<cpan>, set the C<urllist> config option via the shell like this:

  $> cpan
  cpan[1]> o conf urllist file:///path/to/repo
  cpan[2]> reload index
  cpan[3]> install Some::Package
  cpan[4]> o conf commit     # If you want to make the change permanent

Pointing your client at the top of your repository will install modules
from the default stack.  To install from a particular stack, just add it 
to the URL.  For example:

  file:///path/to/repo                # Install from default stack
  file:///path/to/repo/stacks/dev     # Install from "dev" stack
  file:///path/to/repo/stacks/prod    # Install from "prod" stack

If your repository does not have a default stack then you must specify the
full URL to one of the stacks as shown above.

=head1 COMPATIBILITY

The C<install> does not support some of the newer features found in
version 1.6 (or later) of L<cpanm>, such as installing from a Git 
repository, installing development releases, or using complex version 
expressions. If you pass any of those as arguments to this command, the 
behavior is unspecified.

=cut
