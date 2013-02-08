# ABSTRACT: Interface to the version control subsystem

package Pinto::VCS;

use Moose;
use MooseX::MarkAsMethods (autoclean => 1);

use Git::Raw;
use DateTime;
use Readonly;
use Path::Class;
use File::Copy ();
use Try::Tiny;

use Pinto::Types qw(Dir);
use Pinto::Util qw(itis);
use Pinto::Exception qw(throw);
use Pinto::CommitWalker;
use Pinto::Commit;
use Pinto::Diff;

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

Readonly::Scalar our $GIT_REPO_NOT_BARE   => 0;
Readonly::Scalar our $GIT_BRANCH_IS_LOCAL => 1;
Readonly::Scalar our $GIT_RESET_TYPE_HARD => 'hard';

#-------------------------------------------------------------------------------

sub initialize {
    my ($self) = @_;

    my $vcs_dir = $self->config->vcs_dir;

    throw "VCS is already initialized" if -e $vcs_dir->subdir('.git');

    $vcs_dir->mkpath if not -e $vcs_dir;

    Git::Raw::Repository->init($vcs_dir, $GIT_REPO_NOT_BARE);

    return $self;
}

#-------------------------------------------------------------------------------

sub fork_branch {
    my ($self, %args) = @_;

    my $from = $args{from};
    my $to   = $args{to};

    my $branch_ref = $self->_get_branch_ref($from);

    $self->git->branch($to, $branch_ref->target);

    return $self;
}

#-------------------------------------------------------------------------------

sub rename_branch {
    my ($self, %args) = @_;

    my $from = $args{from};
    my $to   = $args{to};

    my $branch_ref = $self->_get_branch_ref($from);

    $branch_ref->move($to, 0);

    return $self;
}

#-------------------------------------------------------------------------------

sub delete_branch {
    my ($self, %args) = @_;

    my $branch = $args{branch};

    my $branch_ref = $self->_get_branch_ref($branch);

    $branch_ref->delete;

    return $self;
}

#-------------------------------------------------------------------------------

sub checkout_branch {
    my ($self, %args) = @_;

    my $name      = $args{name};
    my $as_orphan = $args{as_orphan};

    if ($as_orphan) {
        # HACK: Trick git into having an orphan branch.  It is not
        # clear how to do this properly via the libgit2 API.
        my $fh = $self->vcs_dir->subdir('.git')->file('HEAD')->openw;
        print { $fh } "ref: refs/heads/$name\n";
        $self->git->index->clear; # ??
        $self->git->index->write; # ??
        return $self;
    }

    my $branch_ref = $self->_get_branch_ref($name);
    my $opts       = { checkout_strategy => {force => 1} };

    $self->git->checkout($branch_ref->target, $opts);
    $self->git->head($branch_ref);

    return $self;
}

#-------------------------------------------------------------------------------

sub add {
    my ($self, %args) = @_;

    my $file = $args{file};
    $file    = file($file) if not itis($file, 'Path::Class');

    my $dir = $self->vcs_dir->subdir($file->parent);
    $dir->mkpath unless -e $dir;

    if (my $from = $args{from}) {
        $from = file($from) if not itis($from, 'Path::Class');
        File::Copy::copy($from => $dir) or throw "Copy failed: $!";
    }

    my $index = $self->git->index;
    $index->add($file);
    $index->write;

    return $dir->file($file);
}

#-------------------------------------------------------------------------------

sub commit {
    my ($self, %args) = @_;

    my $user      = $args{username} || $self->config->username;
    my $message   = $args{message};
    my $as_orphan = $args{as_orphan};

    $message ||= 'Initial commit' if $as_orphan;

    my $tree_id = $self->git->index->write_tree;
    my $tree    = $self->git->lookup($tree_id);
    my $me      = Git::Raw::Signature->now($user, $user);
    my $parents = $as_orphan ? [] : [$self->git->head->target];
    my $commit  = $self->git->commit($message, $me, $me, $parents, $tree);

    return $commit->id;
}

#-------------------------------------------------------------------------------

sub history {
    my ($self, %args) = @_;

    my $branch = $args{branch};
    my $walker = $self->git->walker;

    my $branch_ref = $self->_get_branch_ref($branch);
    $walker->push($branch_ref->target);

    return Pinto::CommitWalker->new(raw_walker => $walker);
}

#-------------------------------------------------------------------------------

sub get_commit {
    my ($self, %args) = @_;

    my $commit_id = $args{commit_id};

    my $commit_ref = $self->_get_commit_ref($commit_id);

    return Pinto::Commit->new(raw_commit => $commit_ref);
}

#-------------------------------------------------------------------------------

sub diff {
    my ($self, %args) = @_;

    my $left_commit_id = $args{left_commit_id};
    my $left_tree = $self->_get_commit_ref($left_commit_id)->tree;

    my $right_commit_id = $args{right_commit_id};
    my $right_tree = $self->_get_commit_ref($right_commit_id)->tree;

    my $diff = $left_tree->diff($self->git, $right_tree);

    return Pinto::Diff->new(raw_diff => $diff);
}

#-------------------------------------------------------------------------------

sub diff_wc {
    my ($self) = @_;

    my $diff = $self->git->diff;

    return Pinto::Diff->new(raw_diff => $diff);
}

#-------------------------------------------------------------------------------

sub merge {
    # Attempt to merge branches
}

#-------------------------------------------------------------------------------

sub reset {
    my ($self, %args) = @_;

    my $commit = $self->_get_commit_ref($args{commit});

    $self->git->reset($commit, $GIT_RESET_TYPE_HARD);

    return $self;
}

#-------------------------------------------------------------------------------

sub status {
    my ($self, %args) = @_;

    my $file   = $args{file};
    my $status = $self->git->status($file);

    return $status ? 1 : 0;
}

#-------------------------------------------------------------------------------

sub _get_branch_ref {
    my ($self, $branch_name) = @_;

    my $branch = try {
        Git::Raw::Branch->lookup($self->git, $branch_name, $GIT_BRANCH_IS_LOCAL);
    }
    catch {
        throw "Branch $branch_name does not exist" if m/not found/;
        throw "VCS error: $_";
    };

    return $branch;
}


#-------------------------------------------------------------------------------

sub _get_commit_ref {
    my ($self, $commit_id) = @_;

    my $commit = try {
        Git::Raw::Commit->lookup($self->git, $commit_id);
    }
    catch {
        throw "Commit $commit_id does not exist" if m/not found/;
        throw "VCS error: $_";
    };

    return $commit;
}

#-------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#-------------------------------------------------------------------------------

1;

__END__
