# ABSTRACT: create a new repository

package App::Pinto::Command::init;

use strict;
use warnings;

use Class::Load;
use Pinto::Util qw(is_remote_repo);

#-----------------------------------------------------------------------------

use base 'App::Pinto::Command';

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

sub opt_spec {
    my ( $self, $app ) = @_;

    return (
        [ 'description=s'             => 'Description of the initial stack' ],
        [ 'no-default'                => 'Do not mark the initial stack as the default' ],
        [ 'recurse!'                  => 'Default recursive behavior (negatable)' ],
        [ 'source=s@'                 => 'URI of upstream repository (repeatable)' ],
        [ 'stack=s'                   => 'Name of the initial stack' ],
        [ 'target-perl-version|tpv=s' => 'Default perl version for new stacks' ],
    );
}

#------------------------------------------------------------------------------

sub validate_args {
    my ( $self, $opts, $args ) = @_;

    $self->usage_error('Only one argument is allowed')
        if @{$args} > 1;

    return 1;
}

#------------------------------------------------------------------------------

sub execute {
    my ( $self, $opts, $args ) = @_;

    my $global_opts = $self->app->global_options;

    die "Must specify a repository root directory\n"
        unless $global_opts->{root} ||=
            ($args->[0] || $ENV{PINTO_REPOSITORY_ROOT});

    die "Cannot create remote repositories\n"
        if is_remote_repo( $global_opts->{root} );

    # Combine repeatable "source" options into one space-delimited "sources" option.
    # TODO: Use a config file format that allows multiple values per key (MVP perhaps?).
    $opts->{sources} = join ' ', @{ delete $opts->{source} } if defined $opts->{source};

    my $initializer = $self->load_initializer->new;
    $initializer->init( %{$global_opts}, %{$opts} );
    return 0;
}

#------------------------------------------------------------------------------

sub load_initializer {

    my $class = 'Pinto::Initializer';

    my ( $ok, $error ) = Class::Load::try_load_class($class);
    return $class if $ok;

    my $msg = $error =~ m/Can't locate .* in \@INC/    ## no critic (ExtendedFormatting)
        ? "Must install Pinto to create new repositories\n"
        : $error;
    die $msg;
}

#------------------------------------------------------------------------------

1;

__END__

=pod

=head1 SYNOPSIS

  pinto --root=REPOSITORY_ROOT init [OPTIONS]


=head1 DESCRIPTION

This command creates a new repository.  If the target directory does not
exist, it will be created for you.  If it does already exist, then it must be
empty.  You can set the configuration properties of the new repository using
the command line options listed below.


=head1 COMMAND ARGUMENTS

The path to the repository root directory can also be be given as an argument,
which will silently override the C<--root> option.  So the following are
equivalent:

  pinto --root=/some/directory init
  pinto init /some/directory


=head1 COMMAND OPTIONS

=over 4

=item --description=TEXT

A brief description of the initial stack.  Defaults to "the initial stack".
This option is only allowed if the C<STACK> argument is given.


=item --no-default

Do not mark the initial stack as the default stack. If you choose not to mark
the default stack, then you'll be required to specify the C<--stack> option
for most commands.  You can always mark (or unmark) the default stack at any
time by using the L<default|App::Pinto::Command::default> command.


=item --recurse

=item --no-recurse

Sets the default recursion behavior for the L<pull|App::Pinto::Command::pull>
add L<add|App::Pinto::Command::add> commands.  C<--recurse> means that
commands  will be recursive by default.  C<--no-recurse> means commands will
not be  recursive.  If you do not specify either of these, it defaults to
being  recursive.  However, each command can always override this default.


=item --source=URI

The URI of the upstream repository where distributions will be pulled from.
This is usually the URI of a CPAN mirror, and it defaults to
L<http://cpan.perl.org> and L<http://backpan.perl.org>.  But it could  also be
a L<CPAN::Mini> mirror, or another L<Pinto> repository.

You can specify multiple repository URIs by repeating the C<--source> option.
Repositories that appear earlier in the list have priority over those that
appear later.  See L<Pinto::Manual> for more information about using multiple
upstream repositories.


=item --stack=NAME

Sets the name of the initial stack.  Stack names must be alphanumeric plus
hyphens, underscores, and periods, and are not case-sensitive.  Defaults to
C<master>.

=back

=cut
