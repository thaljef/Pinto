# ABSTRACT: Interface to the version control subsystem

package Pinto::VCS;

use Moose;

use Git::Raw;

use Pinto::Types qw(Dir);
use Pinto::Exception qw(throw);

use namespace::autoclean;

#-------------------------------------------------------------------------------

# VERSION

#-------------------------------------------------------------------------------

with qw( Pinto::Role::Configurable
         Pinto::Role::Loggable );

#-------------------------------------------------------------------------------

has vcs_dir => (
    is      => 'ro',
    isa     => Dir,
    default => sub { $_[0]->config->vcs_dir },
    lazy    => 1,
);


has vcs_repo => (
    is      => 'ro',
    isa     => 'Git::Raw::Repository',
    default => sub { Git::Raw::Repository->open($_[0]->vcs_dir) },
    lazy    => 1,
);

#-------------------------------------------------------------------------------

sub initialize {
    my ($self) = @_;

    my $vcs_dir = $self->config->vcs_dir;

    throw "VCS is already initialized" if -e $vcs_dir->subdir('.git');

    Git::Raw::Repository->init($vcs_dir, 0);

    return $self;
}

#-------------------------------------------------------------------------------

sub branch {
    # Create new branch
}

sub checkout {
    # Change to branch or commit
}

sub log {
    # Return revision history
}

sub add {
    # Add file to be committed
}

sub commit {
    # Commit files that have been added
}

sub merge {
    # Attempt to merge branches
}

sub reset {
    # Restore WC to pristine state
}

sub status {
    # True if WC has changed
}

#-------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#-------------------------------------------------------------------------------

1;

__END__
