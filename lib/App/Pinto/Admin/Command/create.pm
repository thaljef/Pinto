package App::Pinto::Admin::Command::create;

# ABSTRACT: create an empty repository

use strict;
use warnings;

use Path::Class;

#-----------------------------------------------------------------------------

use base 'App::Pinto::Admin::Command';

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

sub validate_args {
    my ($self, $opts, $args) = @_;
    $self->usage_error('Arguments are not allowed') if @{ $args };
    return 1;
}

#------------------------------------------------------------------------------

sub execute {
    my ($self, $opts, $args) = @_;

    # HACK...I want to do this before checking out from VCS
    my $repos = $self->pinto->config->repos();
    die "A repository already exists at $repos\n"
        if -e file($repos, qw(modules 02packages.details.txt.gz));

    eval { $repos->mkpath() }
      or die "Unable to make repository at $repos: $@\n";

    $self->pinto->new_action_batch( %{$opts} );
    $self->pinto->add_action('Create', %{$opts});
    my $ok = $self->pinto->run_actions();
    return $ok ? 0 : 1;
}

#------------------------------------------------------------------------------

1;

__END__
