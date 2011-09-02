package App::Pinto::Admin::Command::create;

# ABSTRACT: create a new empty repository

use strict;
use warnings;

use Pinto::Creator;

#-----------------------------------------------------------------------------

use base 'App::Pinto::Admin::Command';

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

sub command_names { return qw( create new ) }

#------------------------------------------------------------------------------

sub validate_args {
    my ($self, $opts, $args) = @_;

    $self->usage_error('Arguments are not allowed') if @{ $args };

    return 1;
}

#------------------------------------------------------------------------------

sub execute {
    my ($self, $opts, $args) = @_;

    $DB::single = 1;

    my $repos = $self->app->global_options()->{repos}
        or die 'Must specify a repository directory';

    my $creator = Pinto::Creator->new( repos => $repos );
    $creator->create();
    return 0;
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
