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

sub execute {
    my ($self, $opts, $args) = @_;

    $self->pinto->new_batch( %{$opts} );
    $self->pinto->add_action( $self->action_name(), %{$opts} );
    my $result = $self->pinto->run_actions();

    return $result->is_success() ? 0 : 1;
}

#-----------------------------------------------------------------------------

sub action_name {
    my ($self) = @_;

    my $class = ref $self || $self;

    $class =~ m{ ^ Pinto::Admin::(?:Command|Subcommand):: (.+) $ }mx
        or croak "Unable to parse Action name from $class";

    # Convert foo::bar::baz -> Foo::Bar:Baz
    # TODO: consider using a regex to do the conversion
    my $action_name = join '::', map {ucfirst} split '::', $1;

    return $action_name;
}

#-----------------------------------------------------------------------------
1;

__END__
