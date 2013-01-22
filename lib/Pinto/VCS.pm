# ABSTRACT: Interface to the version control subsystem

package Pinto::VCS;

use Moose;

use Git::Raw;
use File::Touch ();

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


has git     => (
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

    $vcs_dir->mkpath;

    Git::Raw::Repository->init($vcs_dir, 0);

    return $self;
}

#-------------------------------------------------------------------------------

sub branch {
    my ($self, $from, $to) = @_;

    my $target = $self->git->lookup($from)
        or throw "Target $from does not exist in version control";

    $self->git->checkout($target);
    $self->git->branch($to, $self->repo->head);

    return $self;
}

#-------------------------------------------------------------------------------

sub checkout {
    my ($self, $branch_name) = @_;

    my $branch = Git::Raw::Branch->lookup($self->git, $branch_name, 1);
    $self->git->checkout($branch, {});

    return $self;
}

#-------------------------------------------------------------------------------

sub touch {
    my ($self, $file) = @_;

    # TODO: mksubdirs if needed
    my $path = $self->config->vcs_dir->file($file);
    File::Touch::touch( $path->stringify ) or die $!;

    return $self;
}

#-------------------------------------------------------------------------------

sub log {
    # Return revision history
}

#-------------------------------------------------------------------------------

sub add {
    my ($self, $file) = @_;

    # TODO: mksubdirs if needed
    my $index = $self->git-> index;
    $index->add($file);
    $index->write;

    return $self;
}

#-------------------------------------------------------------------------------

sub commit {
    my ($self, %args) = @_;

    my $user    = $args{username} || $self->config->username;
    my $message = $args{message};
    my $orphan  = $args{orphan};

    my $tree_id = $self->git->index->write_tree;
    my $tree    = $self->git->lookup($tree_id);
    my $me      = Git::Raw::Signature->now($user, $user);
    my $parents = $orphan ? [] : $self->git->head->target;
    my $commit  = $self->git->commit($message, $me, $me, $parents, $tree);

    return $commit->id;
}

#-------------------------------------------------------------------------------

sub merge {
    # Attempt to merge branches
}

sub reset {
    # Restore WC to pristine state
}

sub status {
    my ($self, %args) = @_;

    my $file   = $args{file};
    my $status = $self->git->status($file);

    return $status ? 1 : 0;
}

#-------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#-------------------------------------------------------------------------------

1;

__END__
