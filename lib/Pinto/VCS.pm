# ABSTRACT: Interface to the version control subsystem

package Pinto::VCS;

use Moose;

use Git::Raw;
use Path::Class;
use File::Copy ();

use Pinto::Types qw(Dir);
use Pinto::Util qw(itis);
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
    # TODO: make root commit?

    return $self;
}

#-------------------------------------------------------------------------------

sub fork_branch {
    my ($self, %args) = @_;

    my $from = $args{from};
    my $to   = $args{to};

    my $branch_ref = Git::Raw::Branch->lookup($self->git, $from, 1);

    $self->git->branch($to, $branch_ref->target);

    return $self;
}

#-------------------------------------------------------------------------------

sub rename_branch {
    my ($self, %args) = @_;

    my $from = $args{from};
    my $to   = $args{to};

    my $branch_ref = Git::Raw::Branch->lookup($self->git, $from, 1);

    $branch_ref->move($to, 0);

    return $self;
}

#-------------------------------------------------------------------------------

sub delete_branch {
    my ($self, %args) = @_;

    my $branch = $args{branch};

    my $branch_ref = Git::Raw::Branch->lookup($self->git, $branch, 1);

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

    my $branch = Git::Raw::Branch->lookup($self->git, $name, 1);
    my $opts  = { checkout_strategy => {force => 1} };

    $self->git->checkout($branch->target, $opts);
    $self->git->head($branch);

    return $self;
}

#-------------------------------------------------------------------------------

sub log {
    # Return revision history
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

    return $self;
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
