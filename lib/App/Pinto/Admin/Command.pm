package App::Pinto::Admin::Command;

# ABSTRACT: Base class for pinto-admin commands

use strict;
use warnings;

use Carp;

#-----------------------------------------------------------------------------

use App::Cmd::Setup -command;

#-----------------------------------------------------------------------------

# VERSION

#-----------------------------------------------------------------------------

sub usage_desc {
    my ($self) = @_;

    my ($command) = $self->command_names();

    return "%c --root=PATH $command [OPTIONS] [ARGS]"
}

#-----------------------------------------------------------------------------

sub pinto {
    my ($self) = @_;
    return $self->app->pinto();
}

#-----------------------------------------------------------------------------

sub validate_args {
    my ($self, $opts, $args) = @_;

    $self->usage_error("Arguments are not allowed")
      if @{ $args } and not $self->args_attribute;

    return 1;
}

#------------------------------------------------------------------------------

sub execute {
    my ($self, $opts, $args) = @_;

    my %args = $self->process_args($args);
    my $result = $self->pinto->run($self->action_name, %{$opts}, %args);

    return $result->exit_status;
}

#-----------------------------------------------------------------------------

sub process_args {
    my ($self, $args) = @_;

    my $attr = $self->args_attribute or return;

    if ( ! @{$args} && $self->args_from_stdin) {
        return ($attr => [ Pinto::Util::args_from_fh(\*STDIN) ]);
    }

    return ($attr => $args);
}

#-----------------------------------------------------------------------------

sub action_name {
    my ($self) = @_;

    my $class = ref $self || $self;  # why ref $self ??
    my $prefix = $self->command_namespace_prefix();

    $class =~ m/ ^ ${prefix}:: (.+) /mx
        or confess "Unable to parse Action name from $class";

    # Convert foo::bar::baz -> Foo::Bar:Baz
    # TODO: consider using a regex to do the conversion
    my $action_name = join '::', map {ucfirst} split '::', $1;

    return $action_name;
}

#-----------------------------------------------------------------------------

sub args_attribute { return '' }

#-----------------------------------------------------------------------------

sub args_from_stdin { return 0 }

#-----------------------------------------------------------------------------

sub command_namespace_prefix { return __PACKAGE__ }

#-----------------------------------------------------------------------------
1;

__END__
