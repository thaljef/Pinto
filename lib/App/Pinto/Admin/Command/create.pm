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

    $self->SUPER::validate_args($opts, $args);

    $self->usage_error('Arguments are not allowed') if @{ $args };

    return 1;
}

#------------------------------------------------------------------------------

sub execute {
    my ($self, $opts, $args) = @_;

    # HACK...I want to do this before checking out from VCS
    my $repos = $self->pinto->config->repos();
    die "Directory $repos is not empty\n"
        if -e $repos and $repos->children();


    $self->pinto->new_action_batch( %{$opts}, nolock => 1 );
    $self->pinto->add_action('Create', %{$opts});
    my $result = $self->pinto->run_actions();
    return $result->is_success() ? 0 : 1;
}

#------------------------------------------------------------------------------

1;

__END__

=head1 SYNOPSIS

  pinto-admin --repos=/some/dir create

=head1 DESCRIPTION

This command creates a new, empty repository.  If the target directory
does not exist, it will be created for you.  If it does already exist,
then it must be empty.  The new repository will contain empty index
files and the default configuration.

If you are going to be using a VCS-based Store for your repository,
then the creation process is a little more complicated.  See the
documentation of your chosen Store class for details.

=head1 COMMAND ARGUMENTS

None.

=head1 COMMAND OPTIONS

None.

=cut
