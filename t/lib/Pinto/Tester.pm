# ABSTRACT: A class for testing a Pinto repository

package Pinto::Tester;

use Moose;
use MooseX::NonMoose;
use MooseX::StrictConstructor;
use MooseX::Types::Moose qw(ScalarRef HashRef);

use Test::Exception;

use Pinto;
use Pinto::Globals;
use Pinto::Initializer;
use Pinto::Chrome::Term;
use Pinto::Tester::Util qw(:all);
use Pinto::Types qw(Uri Dir);
use Pinto::Util qw(:all);

use overload (q{""} => 'to_string');

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

extends qw(Test::Builder::Module);

#------------------------------------------------------------------------------

BEGIN {

    # So we don't prompt for commit messages
    $Pinto::Globals::is_interactive = 0;

    # So the username/author is constant
    $Pinto::Globals::current_author_id = 'AUTHOR';
    $Pinto::Globals::current_username  = 'USERNAME';

}

#------------------------------------------------------------------------------

has pinto_args => (
    isa     => HashRef,
    default => sub { {} },
    traits  => ['Hash'],
    handles => { pinto_args => 'elements' },
    lazy    => 1,
);

has init_args => (
    isa     => HashRef,
    default => sub { {} },
    traits  => ['Hash'],
    handles => { init_args => 'elements' },
    lazy    => 1,
);

has root => (
    is      => 'ro',
    isa     => Dir,
    default => sub { tempdir },
    lazy    => 1,
);

has pinto => (
    is      => 'ro',
    isa     => 'Pinto',
    builder => '_build_pinto',
    lazy    => 1,
);

has repo => (
    is       => 'ro',
    isa      => 'Pinto::Repository',
    handles  => [ qw(get_stack get_stack_maybe get_distribution) ],
    default  => sub { $_[0]->pinto->repo },
    init_arg => undef,
    lazy     => 1,
);

has outstr => (
    is      => 'rw',
    isa     => ScalarRef,
    default => sub { my $str = ''; return \$str },
);

has errstr => (
    is      => 'rw',
    isa     => ScalarRef,
    default => sub { my $str = ''; return \$str },
);

has tb => (
    is       => 'ro',
    isa      => 'Test::Builder',
    handles  => [qw(ok is_eq isnt_eq diag like unlike)],
    default  => sub { my $tb = __PACKAGE__->builder; $tb->level(2); return $tb },
    init_arg => undef,
);

#------------------------------------------------------------------------------
# This force the repository to be constructed immediately.  Just
# making the 'pinto' attribute non-lazy didn't work, probably due to
# dependencies on other attributes.

sub BUILD { $_[0]->pinto }

#------------------------------------------------------------------------------

sub _build_pinto {
    my ($self) = @_;

    my $chrome = Pinto::Chrome::Term->new(
        verbose  => 2,
        color    => 0,
        stdout   => $self->outstr,
        stderr   => $self->errstr,
    );

    my %defaults = ( root => $self->root );

    my $initializer = Pinto::Initializer->new;
    $initializer->init( %defaults, $self->init_args );

    return Pinto->new( %defaults, chrome => $chrome, $self->pinto_args );
}

#------------------------------------------------------------------------------

sub path_exists_ok {
    my ( $self, $path, $name ) = @_;

    $path = ref $path eq 'ARRAY' ? $self->root->file( @{$path} ) : $path;
    $name ||= "Path $path should exist";

    $self->ok( -e $path, $name );

    return;
}

#------------------------------------------------------------------------------

sub path_not_exists_ok {
    my ( $self, $path, $name ) = @_;

    $path = ref $path eq 'ARRAY' ? $self->root->file( @{$path} ) : $path;
    $name ||= "Path $path should not exist";

    $self->ok( !-e $path, $name );

    return;
}

#------------------------------------------------------------------------------

sub run_ok {
    my ( $self, $action_name, $args, $test_name ) = @_;

    local $Pinto::Globals::is_interactive = 0;
    local $Test::Builder::Level           = $Test::Builder::Level + 1;

    $self->clear_buffers;
    my $result = $self->pinto->run( $action_name, %{$args} );
    $self->result_ok( $result, $test_name );

    return $result;
}

#------------------------------------------------------------------------------

sub run_throws_ok {
    my ( $self, $action_name, $args, $error_regex, $test_name ) = @_;

    local $Pinto::Globals::is_interactive = 0;
    local $Test::Builder::Level           = $Test::Builder::Level + 1;

    $self->clear_buffers;
    my $result = $self->pinto->run( $action_name, %{$args} );
    $self->result_not_ok( $result, $test_name );

    my $ok = $self->like( $result->to_string, $error_regex, $test_name );

    $self->diag_stderr if not $ok;

    return $ok;
}

#------------------------------------------------------------------------------

sub registration_ok {
    my ( $self, $reg_spec ) = @_;

    my ( $author, $dist_archive, $pkg_name, $pkg_ver, $stack_name, $is_pinned ) = parse_reg_spec($reg_spec);

    my $author_dir = Pinto::Util::author_dir($author);
    my $dist_path  = $author_dir->file($dist_archive)->as_foreign('Unix');
    my $stack      = $self->get_stack($stack_name);

    my $where = { revision => $stack->head->id, 'package.name' => $pkg_name };
    my $attrs = { prefetch => { package => 'distribution' } };
    my $reg = $self->pinto->repo->db->schema->find_registration( $where, $attrs );

    return $self->ok( 0, "Package $pkg_name is not on stack $stack_name" )
        if not $reg;

    #-------------------------------------
    # Test package object...

    my $pkg = $reg->package;
    $self->is_eq( $pkg->name,    $pkg_name, "Package has correct name" );
    $self->is_eq( $pkg->version, $pkg_ver,  "Package has correct version" );

    # Test distribution object...
    my $dist = $reg->distribution;
    $self->is_eq( $dist->path, $dist_path, "Distribution has correct dist path" );

    # Test pins...
    $self->ok( $reg->is_pinned, "Registration $reg should be pinned" )
        if $is_pinned;

    $self->ok( !$reg->is_pinned, "Registration $reg should not be pinned" )
        if not $is_pinned;

    #-------------------------------------
    # Test file paths...

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    $self->path_exists_ok( [ qw(authors id), $author_dir, 'CHECKSUMS' ] );

    # Reach file through the stack's authors/id directory
    $self->path_exists_ok( $dist->native_path( $stack->authors_dir->subdir('id') ) );

    # Reach file through the top authors/id directory
    $self->path_exists_ok( $dist->native_path );

    return;
}

#------------------------------------------------------------------------------

sub registration_not_ok {
    my ( $self, $reg_spec ) = @_;

    my ( $author, $archive, $pkg_name, $pkg_ver, $stack_name, $is_pinned ) = parse_reg_spec($reg_spec);

    my $author_dir = Pinto::Util::author_dir($author);
    my $dist_path  = $author_dir->file($archive)->as_foreign('Unix');
    my $stack      = $self->get_stack($stack_name);

    my $where = {
        stack                  => $stack->id,
        'package.name'         => $pkg_name,
        'distribution.author'  => $author,
        'distribution.archive' => $archive
    };

    my $reg = $self->pinto->repo->db->schema->search_registration($where);

    return $self->ok( 1, "Registration $reg_spec should not exist" )
        if not $reg;
}

#------------------------------------------------------------------------------

sub result_ok {
    my ( $self, $result ) = @_;

    my $test_name = 'Result indicates action was succesful';
    my $ok = $self->ok( $result->was_successful, $test_name );
    $self->diag_stderr if not $ok;

    return;
}

#------------------------------------------------------------------------------

sub result_not_ok {
    my ( $self, $result ) = @_;

    my $test_name = 'Result indicates action was not succesful';
    my $ok = $self->ok( !$result->was_successful, $test_name );
    $self->diag_stderr if not $ok;

    return;
}

#------------------------------------------------------------------------------

sub result_changed_ok {
    my ( $self, $result ) = @_;

    my $test_name = 'Result indicates changes were made';
    my $ok = $self->ok( $result->made_changes, $test_name );
    $self->diag_stderr if not $ok;

    return;
}

#------------------------------------------------------------------------------

sub result_not_changed_ok {
    my ( $self, $result ) = @_;

    my $test_name = 'Result indicates changes were not made';
    my $ok = $self->ok( !$result->made_changes, $test_name );
    $self->diag_stderr if not $ok;

    return;
}

#------------------------------------------------------------------------------

sub repository_clean_ok {
    my ($self) = @_;

    my $dists = $self->pinto->repo->distribution_count;
    $self->is_eq( $dists, 0, 'Repo has no distributions' );

    my $pkgs = $self->pinto->repo->package_count;
    $self->is_eq( $pkgs, 0, 'Repo has no packages' );

    my @stacks = $self->pinto->repo->get_all_stacks;
    $self->is_eq( scalar @stacks, 1, 'Repo has only one stack' );

    my $stack = $stacks[0];
    $self->is_eq( $stack->name,       'master', 'The stack is called "master"' );
    $self->is_eq( $stack->is_default, 1,        'The stack is marked as default' );

    my $authors_id_dir = $self->pinto->repo->config->authors_id_dir;
    $self->ok( !-e $authors_id_dir, 'The authors/id dir should be gone' );

    return;
}

#------------------------------------------------------------------------------

sub diag_stderr {
    my ($self) = @_;
    my $errs = ${ $self->errstr };
    $self->diag('Log messages are...');
    $self->diag($errs);
}

#------------------------------------------------------------------------------

sub stdout_like {
    my ( $self, $rx, $name ) = @_;

    $name ||= 'stdout output matches';
    $self->like( ${ $self->outstr }, $rx, $name );

    return;
}

#------------------------------------------------------------------------------

sub stdout_unlike {
    my ( $self, $rx, $name ) = @_;

    $name ||= 'stdout does not match';
    $self->unlike( ${ $self->outstr }, $rx, $name );

    return;
}

#------------------------------------------------------------------------------

sub stderr_like {
    my ( $self, $rx, $name ) = @_;

    $name ||= 'stderr output matches';
    $self->like( ${ $self->errstr }, $rx, $name );

    return;
}

#------------------------------------------------------------------------------

sub stderr_unlike {
    my ( $self, $rx, $name ) = @_;

    $name ||= 'stderr does not match';
    $self->unlike( ${ $self->errstr }, $rx, $name );

    return;
}

#------------------------------------------------------------------------------

sub stack_is_default_ok {
    my ( $self, $stack_name, $test_name ) = @_;

    $test_name ||= '';

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $stack = $self->get_stack($stack_name);
    $self->ok( $stack->is_default, "Stack $stack is marked as default $test_name" );

    my $stack_modules_dir = $stack->modules_dir;
    my $repo_modules_dir  = $self->pinto->repo->config->modules_dir;

    $self->ok( -e $repo_modules_dir, "The modules dir exists $test_name" ) or return;

    my $inode1 = $repo_modules_dir->stat->ino;
    my $inode2 = $stack_modules_dir->stat->ino;

    $self->is_eq( $inode1, $inode2, "The modules dir is linked to $stack $test_name" );

    return $stack;
}

#------------------------------------------------------------------------------

sub stack_is_not_default_ok {
    my ( $self, $stack_name, $test_name ) = @_;

    my $stack = $self->get_stack($stack_name);
    $self->ok( !$stack->is_default, "Stack $stack not marked as default" );

    my $stack_modules_dir = $stack->modules_dir;
    my $repo_modules_dir  = $self->pinto->repo->config->modules_dir;

    -l $repo_modules_dir or return;    # Might not be any default

    my $inode1 = $repo_modules_dir->stat->ino;
    my $inode2 = $stack_modules_dir->stat->ino;

    $test_name ||= "The modules dir is not linked to stack $stack";
    $self->isnt_eq( $inode1, $inode2, $test_name );

    return $stack;
}

#------------------------------------------------------------------------------

sub no_default_stack_ok {
    my ($self) = @_;

    my $stack = eval { $self->get_stack };
    $self->ok( !$stack, "No stack should be marked as default" );

    my $modules_dir = $self->pinto->repo->config->modules_dir;
    $self->ok( !-l $modules_dir, "The modules dir is not linked anywhere" );

    return;
}

#------------------------------------------------------------------------------

sub stack_exists_ok {
    my ( $self, $stack_name ) = @_;

    my $stack = $self->get_stack($stack_name);
    $self->ok( $stack, "Stack $stack_name should exist in DB" );

    my $stack_dir = $self->pinto->repo->config->stacks_dir->subdir($stack_name);
    $self->ok( -e $stack_dir, "Directory for $stack_name should exist" );

    return $stack;
}

#------------------------------------------------------------------------------

sub stack_not_exists_ok {
    my ( $self, $stack_name ) = @_;

    my $stack = $self->get_stack_maybe($stack_name);
    $self->ok( !$stack, "Stack $stack_name should not exist in DB" );

    my $stack_dir = $self->pinto->repo->config->stacks_dir->subdir($stack_name);
    $self->ok( !-e $stack_dir, "Directory for $stack_name should not exist" );

    return;
}

#------------------------------------------------------------------------------

sub stack_is_locked_ok {
    my ( $self, $stack_name ) = @_;

    my $stack = $self->get_stack_maybe($stack_name);
    $self->ok( $stack, "Stack $stack_name should exist in DB" ) or return;
    $self->ok( $stack->is_locked, "Stack $stack_name should be locked" );

    return;
}

#------------------------------------------------------------------------------

sub stack_is_not_locked_ok {
    my ( $self, $stack_name ) = @_;

    my $stack = $self->get_stack_maybe($stack_name);
    $self->ok( $stack, "Stack $stack_name should exist in DB" ) or return;
    $self->ok( !$stack->is_locked, "Stack $stack_name should not be locked" );

    return;
}

#------------------------------------------------------------------------------

sub stack_is_empty_ok {
    my ($self, $stack_name ) = @_;

    my $stack = $self->get_stack_maybe($stack_name);
    $self->ok( $stack, "Stack $stack_name should exist in DB" ) or return;
    $self->is_eq($stack->head->registrations->count, 0, "Stack $stack_name should be empty" );

    return;
}
#------------------------------------------------------------------------------

sub populate {
    my ( $self, @specs ) = @_;

    for my $spec (@specs) {
        my $struct  = make_dist_struct($spec);
        my $archive = make_dist_archive($struct);
        my $message = "Populated repository with $spec";

        my $args = {
            recurse    => 0,
            archives   => $archive,
            author     => $struct->{cpan_author},
            message    => $message
        };

        my $r = $self->run_ok( 'Add', $args, $message );
        throw 'Population failed. Aborting test' unless $r->was_successful;
    }

    return $self;
}

#------------------------------------------------------------------------------

sub clear_cache {
    my ($self) = @_;

    $self->pinto->repo->clear_cache;

    return $self;
}

#------------------------------------------------------------------------------

sub clear_buffers {
    my ($self) = @_;

    $self->pinto->chrome->stderr->truncate;
    $self->pinto->chrome->stdout->truncate;

    return $self;
}

#------------------------------------------------------------------------------

sub stack_url {
    my ( $self, $stack_name ) = @_;

    $stack_name ||= 'master';

    return URI->new( 'file://' . $self->root->resolve->absolute . "/stacks/$stack_name" );
}
#-------------------------------------------------------------------------------

sub to_string {
    my ($self) = @_;

    return $self->stack_url->as_string;
}

#------------------------------------------------------------------------------
1;

__END__
