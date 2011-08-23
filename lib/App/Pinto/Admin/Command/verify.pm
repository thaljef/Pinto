package App::Pinto::Admin::Command::verify;

# ABSTRACT: verify that all the indexed distributions are present

use strict;
use warnings;

#-----------------------------------------------------------------------------

use base 'App::Pinto::Admin::Command';

#------------------------------------------------------------------------------

# VERSION

#-----------------------------------------------------------------------------


sub validate_args {
    my ($self, $opt, $args) = @_;
    $self->usage_error("Arguments are not allowed") if @{ $args };
    return 1;
}

#------------------------------------------------------------------------------

sub execute {
    my ($self, $opts, $args) = @_;

    $self->pinto->new_action_batch( %{$opts} );
    $self->pinto->add_action('Verify', %{$opts});
    my $result = $self->pinto->run_actions();
    return $result->is_success() ? 0 : 1;
}

#------------------------------------------------------------------------------

1;

__END__
