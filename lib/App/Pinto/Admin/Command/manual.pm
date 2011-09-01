package App::Pinto::Admin::Command::manual;

# ABSTRACT: show the full manual for a command

use strict;
use warnings;

use Pod::Usage qw(pod2usage);

use base qw(App::Pinto::Admin::Command);

#-------------------------------------------------------------------------------

# VERSION

#-------------------------------------------------------------------------------

sub command_names { return qw( manual man --man ) }

#-----------------------------------------------------------------------------

sub usage_desc {
    my ($self) = @_;

    my ($command) = $self->command_names();

    return "%c $command COMMAND"
}

#-------------------------------------------------------------------------------

sub validate_args {
    my ($self, $opts, $args) = @_;

    $self->usage_error("Must specify a command") if @{ $args } != 1;

    return 1;
}

#-------------------------------------------------------------------------------
# This was stolen from App::Cmd::Command::help

sub execute {
    my ($self, $opts, $args) = @_;

    my ($cmd, undef, undef) = $self->app->prepare_command(@$args);

    my $class = ref $cmd;
    (my $relative_path = $class) =~ s< :: ></>xmsg;
    $relative_path .= '.pm';

    my $absolute_path = $INC{$relative_path}
        or die "No manual available for $class";  ## no critic qw(Carping)

    pod2usage(-verbose => 2, -input => $absolute_path, -exitval => 0);

    return 1;
}

#-------------------------------------------------------------------------------
1;

