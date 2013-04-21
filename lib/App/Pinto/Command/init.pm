# ABSTRACT: create a new repository

package App::Pinto::Command::init;

use strict;
use warnings;

use Class::Load;

#-----------------------------------------------------------------------------

use base 'App::Pinto::Command';

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

sub opt_spec {
    my ($self, $app) = @_;

    return (
        [ 'description=s' => 'Description of the initial stack'             ],
        [ 'no-default'    => 'Do not mark the initial stack as the default' ],
        [ 'no-history'    => 'Do not record stack history'                  ],
        [ 'source=s@'     => 'URL of upstream repository (repeatable)'      ],
    );
}

#------------------------------------------------------------------------------

sub validate_args {
    my ($self, $opts, $args) = @_;

    $self->usage_error('Only one stack argument is allowed')
      if @{ $args } > 1;

    $self->usage_error('Cannot use --description without specifying a stack')
      if $opts->{description} and not @{ $args };

    return 1;
}

#------------------------------------------------------------------------------

sub execute {
    my ($self, $opts, $args) = @_;

    my $global_opts = $self->app->global_options;

    $global_opts->{root} ||= $ENV{PINTO_REPOSITORY_ROOT}
        || die "Must specify a repository root directory\n";

    $global_opts->{root} =~ m{^https?://}x
        && die "Cannot create remote repositories\n";

    # Combine repeatable "source" options into one space-delimited "sources" option.
    # TODO: Use a config file format that allows multiple values per key (MVP perhaps?).
    $opts->{sources} = join ' ', @{ delete $opts->{source} } if defined $opts->{source};

    # Stuff the stack argument into the options hash (if it exists)
    $opts->{stack} = $args->[0] if $args->[0];

    my $initializer = $self->load_initializer->new;
    $initializer->init( %{ $global_opts }, %{$opts} );
    return 0;
}

#------------------------------------------------------------------------------

sub load_initializer {

    my $class = 'Pinto::Initializer';

    my ($ok, $error) = Class::Load::try_load_class($class);
    return $class if $ok;

    my $msg = $error =~ m/Can't locate .* in \@INC/ ## no critic (ExtendedFormatting)
                     ? "Must install Pinto to create new repositories\n"
                     : $error;
    die $msg;
}

#------------------------------------------------------------------------------

1;

__END__

=pod

=head1 SYNOPSIS

  pinto --root=REPOSITORY_ROOT init [OPTIONS] [STACK]


=head1 DESCRIPTION

This command creates a new repository.  If the target directory
does not exist, it will be created for you.  If it does already exist,
then it must be empty.  You can set the configuration properties of
the new repository using the command line options listed below.


=head1 COMMAND ARGUMENTS

The argument is the name of the initial stack.  Stack names must be 
alphanumeric plus hyphens and underscores, and are not case-sensitive.  
Defaults to C<master>.


=head1 COMMAND OPTIONS

=over 4

=item --description=TEXT

A brief description of the initial stack.  Defaults to "the initial
stack".  This option is only allowed if the C<STACK> argument is
given.


=item --no-default

Do not mark the initial stack as the default stack.

If you choose not to mark the default stack, then you'll be required
to specify the C<--stack> option for most commands.  You can always
mark (or unmark) the default stack by at any time by using the
L<default|App::Pinto::Command::default> command.


=item --no-history

!! THIS OPTION IS EXPERIMENTAL !!

Do not record the state of the stack at each revision.  This makes
the database smaller and faster.  But it also means you'll never be 
able to revert, reset, or diff a stack with a prior revision.  
However, log messages will still be recorded and can be displayed as 
usual.  This option should only be used if creating an archival 
repository where you don't really care about the changes in each revision 
(for example, tracking all of BackPAN or CPAN in a Pinto repository).


=item --source=URL

The URL of the upstream repository where distributions will be pulled
from.  This is usually the URL of a CPAN mirror, and it defaults to
L<http://cpan.perl.org> and L<http://backpan.perl.org>.  But it could 
also be a L<CPAN::Mini> mirror, or another L<Pinto> repository.

You can specify multiple repository URLs by repeating the C<--source>
option.  Repositories that appear earlier in the list have priority
over those that appear later.  See L<Pinto::Manual> for more
information about using multiple upstream repositories.

=back

=cut
