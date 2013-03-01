# ABSTRACT: A class for testing a Pinto repository

package Pinto::Tester;

use Moose;
use MooseX::NonMoose;
use MooseX::Types::Moose qw(ScalarRef HashRef);

use Carp;
use IO::String;
use Path::Class;
use File::Temp qw(tempdir);
use Test::Log::Dispatch;
use Test::Exception;

use Pinto;
use Pinto::Util;
use Pinto::Globals;
use Pinto::Initializer;
use Pinto::Tester::Util qw(make_dist_struct make_dist_archive parse_reg_spec);
use Pinto::Types qw(Uri Dir);

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

    # So we can run `prove` without having the ddl installed
    no warnings 'redefine';
    my $ddl_file = file( qw(share pinto.ddl) );
    *Pinto::Database::ddl_file = sub { $ddl_file } if -e $ddl_file;
}

#------------------------------------------------------------------------------

has pinto_args => (
   isa        => HashRef,
   default    => sub { {} },
   traits     => ['Hash'],
   handles    => { pinto_args => 'elements' },
   lazy       => 1,
);


has init_args => (
   isa        => HashRef,
   default    => sub { {} },
   traits     => ['Hash'],
   handles    => { init_args => 'elements' },
   lazy       => 1,
);


has pinto => (
    is       => 'ro',
    isa      => 'Pinto',
    builder  => '_build_pinto',
    lazy     => 1,
);


has root => (
   is       => 'ro',
   isa      => Dir,
   default  => sub { dir( tempdir(CLEANUP => 1) ) },
   lazy     => 1,
);


has tb => (
   is       => 'ro',
   isa      => 'Test::Builder',
   init_arg => undef,
   default  => sub { __PACKAGE__->builder() },
);

#------------------------------------------------------------------------------
# This force the repository to be constructed immediately.  Just
# making the 'pinto' attribute non-lazy didn't work, probably due to
# dependencies on other attributes.

sub BUILD { $_[0]->pinto }

#------------------------------------------------------------------------------

sub _build_pinto {
    my ($self) = @_;

    my %defaults     = ( root    => $self->root() );
    my %log_defaults = ( log_handler => Test::Log::Dispatch->new(),
                         verbose     => 3, );


    my $initializer = Pinto::Initializer->new(%defaults, %log_defaults);
    $initializer->init( $self->init_args );

    my $pinto = Pinto->new(%defaults, %log_defaults, $self->pinto_args);
    return $pinto;
}

#------------------------------------------------------------------------------

sub reset_log {
    my ($self) = @_;

    $self->pinto->logger->log_handler->clear;

    return $self;
}

#------------------------------------------------------------------------------

sub path_exists_ok {
    my ($self, $path, $name) = @_;

    $path = file( $self->root(), @{$path} );
    $name ||= "Path $path exists";

    $self->tb->ok(-e $path, $name);

    return;
}

#------------------------------------------------------------------------------

sub path_not_exists_ok {
    my ($self, $path, $name) = @_;

    $path = file( $self->root(), @{$path} );
    $name ||= "Path $path should not exist";

    $self->tb->ok(! -e $path, $name);

    return;
}

#------------------------------------------------------------------------------

sub run_ok {
    my ($self, $action_name, $args, $test_name) = @_;

    my $result = $self->pinto->run($action_name, %{ $args });
    local $Pinto::Globals::is_interactive = 0;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    $self->result_ok($result, $test_name);

    return $result;
}

#------------------------------------------------------------------------------

sub run_throws_ok {
    my ($self, $action_name, $args, $error_regex, $test_name) = @_;

    local $Pinto::Globals::is_interactive = 0;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my $ok = throws_ok { $self->pinto->run($action_name, %{$args}) }
        $error_regex, $test_name;

    $self->diag_log_contents if not $ok;

    return $ok;
}

#------------------------------------------------------------------------------

sub registration_ok {
    my ($self, $reg_spec) = @_;

    my ($author, $dist_archive, $pkg_name, $pkg_ver, $stack_name, $is_pinned)
        = parse_reg_spec($reg_spec);

    my $author_dir = Pinto::Util::author_dir($author);
    my $dist_path  = $author_dir->file($dist_archive)->as_foreign('Unix');
    my $stack      = $self->pinto->repo->get_stack($stack_name);

    my $where = { stack => $stack->id, 'package.name' => $pkg_name };
    my $attrs = { prefetch => {package => 'distribution' }};
    my $reg = $self->pinto->repo->db->schema->find_registration($where, $attrs);

    return $self->tb->ok(0, "Package $pkg_name is not on stack $stack_name")
        if not $reg;


    # Test package object...
    my $pkg = $reg->    package;
    $self->tb->is_eq($pkg->name,    $pkg_name, "Package has correct name");
    $self->tb->is_eq($pkg->version, $pkg_ver,  "Package has correct version");

    # Test distribution object...
    my $dist = $reg->distribution;
    $self->tb->is_eq($dist->path,  $dist_path, "Distribution has correct dist path");

    # Archive should be reachable through stack symlink (e.g. $stack/authors/id/A/AU/AUTHOR/Foo-1.0.tar.gz)
    $self->path_exists_ok( [$stack_name, qw(authors id), $dist->native_path] );

    # Archive should be reachable through gobal authors dir (e.g. .pinto/authors/id/A/AU/AUTHOR/Foo-1.0.tar.gz)
    $self->path_exists_ok( [ qw(.pinto authors id), $dist->native_path ] );

    # Test pins...
    $self->tb->ok($reg->is_pinned,  "Registration $reg should be pinned") if $is_pinned;
    $self->tb->ok(!$reg->is_pinned, "Registration $reg should not be pinned") if not $is_pinned;

    # Test checksums...
    $self->path_exists_ok( [qw(.pinto authors id), $author_dir, 'CHECKSUMS'] );
    # TODO: test actual checksum values?

    return;
}

#------------------------------------------------------------------------------

sub registration_not_ok {
   my ($self, $reg_spec) = @_;

    my ($author, $dist_archive, $pkg_name, $pkg_ver, $stack_name, $is_pinned)
        = parse_reg_spec($reg_spec);

    my $author_dir = Pinto::Util::author_dir($author);
    my $dist_path = $author_dir->file($dist_archive)->as_foreign('Unix');
    my $stack     = $self->pinto->repo->get_stack($stack_name);

    my $where = {stack => $stack->id, 'package.name' => $pkg_name, 'distribution.author' => $author, 'distribution.archive' => $dist_archive};
    my $reg = $self->pinto->repo->db->schema->search_registration($where);

    return $self->tb->ok(1, "Registration $reg_spec should not exist")
        if not $reg;
}

#------------------------------------------------------------------------------

sub result_ok {
    my ($self, $result, $test_name) = @_;

    $test_name ||= 'Result indicates action was succesful';
    my $ok = $self->tb->ok($result->was_successful, $test_name);
    $self->diag_log_contents if not $ok;

    return $ok;
}

#------------------------------------------------------------------------------

sub result_not_ok {
    my ($self, $result, $test_name) = @_;

    $test_name ||= 'Result indicates action was not succesful';
    my $ok = $self->tb->ok(!$result->was_successful, $test_name);
    $self->diag_log_contents if not $ok;

    return;
}

#------------------------------------------------------------------------------

sub result_changed_ok {
    my ($self, $result, $test_name) = @_;

    $test_name ||= 'Result indicates changes were made';
    my $ok = $self->tb->ok( $result->made_changes, $test_name );
    $self->diag_log_contents if not $ok;

    return $ok;
}

#------------------------------------------------------------------------------

sub result_not_changed_ok {
    my ($self, $result, $test_name) = @_;

    $test_name ||= 'Result indicates changes were not made';
    my $ok = $self->tb->ok( !$result->made_changes, $test_name );
    $self->diag_log_contents if not $ok;

    return $ok;
}

#------------------------------------------------------------------------------

sub repository_clean_ok {
    my ($self) = @_;

    my $dists = $self->pinto->repo->distribution_count;
    $self->tb->is_eq($dists, 0, 'Repo has no distributions');

    my $pkgs = $self->pinto->repo->package_count;
    $self->tb->is_eq($pkgs, 0, 'Repo has no packages');

    my @stacks = $self->pinto->repo->get_all_stacks;
    $self->tb->is_eq(scalar @stacks, 1, 'Repo has only one stack');

    my $stack = $stacks[0];
    $self->tb->is_eq($stack->name, 'master',  'The stack is called "master"');
    $self->tb->is_eq($stack->is_default, 1,  'The stack is marked as default');

    my $authors_id_dir = $self->pinto->config->authors_id_dir;
    $self->tb->ok(! -e $authors_id_dir, 'The authors/id dir should be gone');

    return;
}

#------------------------------------------------------------------------------

sub diag_log_contents {
    my ($self) = @_;
    my $msgs = $self->pinto->logger->log_handler->msgs;
    $self->tb->diag('Log messages are...');
    $self->tb->diag($_->{message}) for @$msgs;
    $self->tb->diag('No log messages seen') if not @$msgs;
}

#------------------------------------------------------------------------------

sub log_like {
    my ($self, $rx, $name) = @_;

    $name ||= 'Log output matches';

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    $self->pinto->logger->log_handler->contains_ok($rx, $name);

    return;
}

#------------------------------------------------------------------------------

sub log_unlike {
    my ($self, $rx, $name) = @_;

    $name ||= 'Log output does not match';

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    $self->pinto->logger->log_handler->does_not_contain_ok($rx, $name);

    return;
}

#------------------------------------------------------------------------------

sub populate {
    my ($self, @specs) = @_;

    for my $spec (@specs) {
        my $struct  = make_dist_struct($spec);
        my $archive = make_dist_archive($struct);
        my $message = "Populated repository with $spec";

        my $args = { norecurse => 1,
                     archives  => $archive,
                     author    => $struct->{cpan_author},
                     message   => $message };

        my $r = $self->run_ok('Add', $args, $message);
        croak 'Population failed. Aborting test' unless $r->was_successful;
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

sub stack_url {
    my ($self, $stack_name) = @_;

    $stack_name ||= 'master';

    return URI->new('file://' . $self->root->resolve->absolute . "/$stack_name");
}

#------------------------------------------------------------------------------
1;

__END__
