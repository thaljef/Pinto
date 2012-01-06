package Pinto::Store::VCS::Git;

# ABSTRACT: Store your Pinto repository locally with Git

use Moose;

use Git::Repository;

use namespace::autoclean;

#-------------------------------------------------------------------------------

# VERSION

#-------------------------------------------------------------------------------
# ISA

extends 'Pinto::Store::VCS';

#-------------------------------------------------------------------------------

has _git => (
    is         => 'ro',
    isa        => 'Git::Repository',
    init_arg   => undef,
    lazy_build => 1,
);

#-------------------------------------------------------------------------------
# Builders

sub _build__git {
    my ($self) = @_;

    my $root = $self->config->root_dir();
    my $dir  = $root;
    my $work_tree;

    for ( 0..3 ) {
        $work_tree = $dir if -e $dir->subdir('.git');
        last if $work_tree;
        $dir = $dir->parent();
    }

    $self->fatal("Could not find .git directory within 4 directories above $root")
        if not $work_tree;

    return Git::Repository->new( work_tree => $work_tree );
}

#-------------------------------------------------------------------------------
# Methods

augment add_path => sub {
    my ($self, %args) = @_;

    # With git, all paths must be relative to the top of the work tree
    my $path = $args{path}->relative( $self->_git->work_tree() );
    $self->_git->run( 'add' => $path->stringify() );
    $self->mark_path_for_commit($path);

    inner();

    return $self;
};

#-------------------------------------------------------------------------------

augment remove_path => sub {
    my ($self, %args) = @_;

    # With git, all paths must be relative to the top of the work tree
    my $path = $args{path}->relative( $self->_git->work_tree() );
    $self->_git->run( rm => '-f',  $path->stringify() );
    $self->mark_path_for_commit($path);

    inner();

    return $self;
};

#-------------------------------------------------------------------------------

augment commit => sub {
    my ($self, %args) = @_;

    my $message = $args{message} || 'NO MESSAGE WAS GIVEN';

    # There could be a lot of paths.  Some OS have a limit on the
    # number of arguments a command can have.  To workaround this, we
    # pass the paths over STDIN (via that 'input' paramter).

    my $paths   = join "\n", map { $_->stringify() } @{ $self->paths_to_commit() };
    $self->_git->run( 'commit' => '-m', $message, {input => $paths} );

    inner();

    return $self;
};

#-------------------------------------------------------------------------------

augment tag => sub {
    my ($self, %args) = @_;

    my $now = DateTime->now();
    my $tag = $now->strftime( $args{tag} );
    my $msg = $args{message};

    $self->info("Tagging at $tag");

    $self->_git->run( tag => '-m', $msg, $tag );

    inner();

    return $self;
};

#-------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#-------------------------------------------------------------------------------

1;

__END__

=head1 SYNOPSIS

  # If you don't already have a Pinto repository, create one (notice the --store option here)
  $> pinto-admin --root=~/PINTO create --store=Pinto::Store::VCS::Git

  # If you do already have a repository, edit its config (at $REPOS/.pinto/config/pinto.ini)
  store = Pinto::Store::VCS::Git

  # Initialize Pinto repository into Git
  $> cd ~/PINTO
  $> git init

  # Add initial files and commit
  $> git add .pinto authors modules
  $> git commit -a -m 'New Pinto repos'

Now run L<pinto-admin> or L<pinto-server> as you normally would,
setting the C<--root> to the path of the working copy (which would be
F<~/PINTO> in the example above).

=head1 DESCRIPTION

L<Pinto::Store::VCS::Git> is a back-end for L<Pinto> that stores the
repository inside a local Git repository.  Before you can effectively
use this Store, you must initialize or clone a Git repository that
contains your Pinto repository (see L</SYNOPSIS> for the typical
procedure).

Note this Store only works with a local Git repository (i.e. one that
does not push or pull to another repository).  If you want to do that,
see L<Pinto::Store::VCS::Git::Remote).

=head1 CAVEATS

=over 4

=item The C<git> program is required.

You must have the binary C<git> tool installed somwhere in uour
C<$PATH> for this Store to work.

=back

=cut
