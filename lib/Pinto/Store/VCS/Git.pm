package Pinto::Store::VCS::Git;

# ABSTRACT: Store your Pinto repository with Git

use Moose;

use Git::Repository;

#-------------------------------------------------------------------------------

# VERSION

#-------------------------------------------------------------------------------
# ISA

extends 'Pinto::Store::VCS';

#-------------------------------------------------------------------------------

has _git => (
    is       => 'ro',
    isa      => 'Git::Repository',
    default  => sub { Git::Repository->new( work_tree => $_[0]->config->root_dir() ) },
    init_arg => undef,
    lazy     => 1,
);

#-------------------------------------------------------------------------------

augment initialize => sub {
    my ($self) = @_;

    $self->_git->run( qw(pull) );

    return $self;
};

#-------------------------------------------------------------------------------

augment add_path => sub {
    my ($self, %args) = @_;

    # With git, all paths must be relative to the top of the work tree
    my $path = $args{path}->relative( $self->config->root_dir() );
    $self->_git->run( 'add' => $path->stringify() );
    $self->mark_path_for_commit($path);

    return $self;
};

#-------------------------------------------------------------------------------

augment remove_path => sub {
    my ($self, %args) = @_;

    # With git, all paths must be relative to the top of the work tree
    my $path = $args{path}->relative( $self->config->root_dir() );
    $self->_git->run( 'rm' => '-f',  $path->stringify() );
    $self->mark_path_for_commit($path);

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
    $self->_git->run( qw(push -u origin master) );

    return $self;
};

#-------------------------------------------------------------------------------

augment tag => sub {
    my ($self, %args) = @_;

    my $now = DateTime->now();
    my $tag = $now->strftime( $args{tag} );

    my $origin = $self->svn_location();

    $self->info("Tagging at $tag");

    my $msg = sprintf 'Tagging Pinto repository as of %s.', $now->datetime();
    $self->_git->run( 'tag' => '-m', $msg, $tag );

    return $self;
};

#-------------------------------------------------------------------------------

1;

__END__

=head1 DESCRIPTION

This module is Not yet implemented.

=cut
