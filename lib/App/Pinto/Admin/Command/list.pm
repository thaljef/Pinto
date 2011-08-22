package App::Pinto::Admin::Command::list;

# ABSTRACT: list the contents of the repository

use strict;
use warnings;

#-----------------------------------------------------------------------------

use base 'App::Pinto::Admin::Command';

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

sub opt_spec {
    return (
        [ 'all'       => 'List both foreign and local dists (default)'],
        [ 'conflicts' => 'List conflicts between local and foreign dists' ],
        [ 'foreign'   => 'List only the foreign dists'],
        [ 'local'     => 'List only the local dists'],
    );
}

#------------------------------------------------------------------------------

sub validate_args {
    my ($self, $opts, $args) = @_;
    $self->usage_error('Arguments are not allowed') if @{ $args };
    return 1;
}

#------------------------------------------------------------------------------

sub execute {
    my ($self, $opts, $args) = @_;

    $self->pinto->new_action_batch( %{$opts} );
    $self->pinto->add_action('List', %{$opts});
    my $ok = $self->pinto->run_actions();
    return $ok ? 0 : 1;

}

#------------------------------------------------------------------------------

1;

__END__
