package App::Pinto::Admin::Command::remove;

# ABSTRACT: remove your own packages from the repository

use strict;
use warnings;

use Pinto::Util;

#-----------------------------------------------------------------------------

use base 'App::Pinto::Admin::Command';

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

sub opt_spec {
    return (
        [ 'author=s'  => 'Your (alphanumeric) author ID' ],
        [ 'message=s' => 'Prepend a message to the VCS log'],
        [ 'nocommit'  => 'Do not commit changes to VCS'],
# TODO       [ 'notag'     => 'Do not create any tag in VCS'],
# TODO       [ 'tag=s'     => 'Specify an alternate tag name' ],
    );
}

#------------------------------------------------------------------------------

sub usage_desc {
    my ($self) = @_;

    my ($command) = $self->command_names();

    return "%c [global options] $command [command options] PACKAGE";
}

#------------------------------------------------------------------------------

sub execute {
    my ($self, $opts, $args) = @_;

    my @args = @{$args} ? @{$args} : Pinto::Util::args_from_fh(\*STDIN);
    return 0 if not @args;

    $self->pinto->new_action_batch( %{$opts} );
    $self->pinto->add_action('Remove', %{$opts}, package => $_) for @{ $args };
    my $result = $self->pinto->run_actions();
    return $result->is_success() ? 0 : 1;
}

#------------------------------------------------------------------------------

1;

__END__
