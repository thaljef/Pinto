package Pinto::Tester;

# ABSTRACT: A class for testing a Pinto repository

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
use Pinto::Creator;
use Pinto::Tester::Util qw(make_dist_struct make_dist_archive);
use Pinto::Types qw(Uri Dir);

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

extends 'Test::Builder::Module';

#------------------------------------------------------------------------------

has pinto_args => (
   isa        => HashRef,
   default    => sub { {} },
   traits     => ['Hash'],
   handles    => { pinto_args => 'elements' },
);


has creator_args => (
   isa        => HashRef,
   default    => sub { {} },
   traits     => ['Hash'],
   handles    => { creator_args => 'elements' },
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


has root_url => (
   is       => 'ro',
   isa      => Uri,
   default  => sub { URI->new('file://' . $_[0]->root->resolve->absolute) },
   lazy     => 1,
);


has tb => (
   is       => 'ro',
   isa      => 'Test::Builder',
   init_arg => undef,
   default  => => sub { __PACKAGE__->builder() },
);

#------------------------------------------------------------------------------

sub _build_pinto {
    my ($self) = @_;

    my %defaults     = ( root    => $self->root() );
    my %log_defaults = ( log_handler => Test::Log::Dispatch->new(),
                         verbose     => 3, );


    my $creator = Pinto::Creator->new(%defaults, %log_defaults);
    $creator->create( $self->creator_args() );

    my $pinto = Pinto->new(%defaults, %log_defaults, $self->pinto_args());
    return $pinto;
}

#------------------------------------------------------------------------------

# for backcompat
sub reset_buffer { goto &reset_log }

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
    $name ||= "Path $path does not exist";

    $self->tb->ok(! -e $path, $name);

    return;
}

#------------------------------------------------------------------------------

sub run_ok {
    my ($self, $action_name, $args, $test_name) = @_;

    my $result = $self->pinto->run($action_name, %{ $args });
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    $self->result_ok($result, $test_name);

    return $result;
}

#------------------------------------------------------------------------------

sub run_throws_ok {
    my ($self, $action_name, $args, $error_regex, $test_name) = @_;

    my $result;
    my $ok = throws_ok { $result = $self->pinto->run($action_name, %{$args}) }
        $error_regex, $test_name;

    $self->diag_log_contents if not $ok;

    return $ok;
}

#------------------------------------------------------------------------------

sub package_ok {
    my ($self, $pkg_spec) = @_;

    my ($author, $dist_archive, $pkg_name, $pkg_ver, $stack_name, $is_pinned)
        = parse_pkg_spec($pkg_spec);

    my $author_dir = Pinto::Util::author_dir($author);
    my $dist_path = $author_dir->file($dist_archive)->as_foreign('Unix');
    my $stack     = $self->pinto->repos->get_stack(name => $stack_name, croak => 1);

    my $where = { stack => $stack->id, name => $pkg_name };
    my $attrs = { prefetch => {package => 'distribution' }};
    my $reg = $self->pinto->repos->db->select_registry($where, $attrs);

    return $self->tb->ok(0, "Package $pkg_name is not on stack $stack_name")
        if not $reg;

    # Test registry object itself...
    $self->tb->is_eq($reg->name, $pkg_name,   'Registry has correct package name');
    $self->tb->is_eq($reg->version, $pkg_ver, 'Registry has correct package version');
    $self->tb->is_eq($reg->path, $dist_path,  'Registry has correct dist path');

    # Test package object...
    my $pkg = $reg->package;
    $self->tb->is_eq($pkg->name,    $pkg_name, "Package has correct name");
    $self->tb->is_eq($pkg->version, $pkg_ver,  "Package has correct version");

    # Test distribution object...
    my $dist = $pkg->distribution;
    $self->tb->is_eq($dist->path,  $dist_path, "Distribution has correct dist path");
    $self->path_exists_ok( [$dist->archive] );

    # Test pins...
    $self->tb->ok($reg->is_pinned,  "$reg is pinned") if $is_pinned;
    $self->tb->ok(!$reg->is_pinned, "$reg is not pinned") if not $is_pinned;

    # Test checksums...
    $self->path_exists_ok( [qw(authors id), $author_dir, 'CHECKSUMS'] );
    # TODO: test actual checksum values?

    return;
}

#------------------------------------------------------------------------------

sub package_not_ok {
   my ($self, $pkg_spec) = @_;

    my ($author, $dist_archive, $pkg_name, $pkg_ver, $stack_name, $is_pinned)
        = parse_pkg_spec($pkg_spec);

    my $author_dir = Pinto::Util::author_dir($author);
    my $dist_path = $author_dir->file($dist_archive)->as_foreign('Unix');
    my $stack     = $self->pinto->repos->get_stack(name => $stack_name, croak => 1);

    my $where = {stack => $stack->id, name => $pkg_name, path => $dist_path};
    my $reg = $self->pinto->repos->db->select_registry($where);

    return $self->tb->ok(1, "$pkg_spec is not registered")
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

sub repository_empty_ok {
    my ($self) = @_;

    my @dists = $self->pinto->repos->db->select_distributions->all;
    $self->tb->is_eq(scalar @dists, 0, 'Database has no distributions');

    my @pkgs = $self->pinto->repos->db->select_packages->all;
    $self->tb->is_eq(scalar @pkgs, 0, 'Database has no packages');

    my $dir = dir( $self->root(), qw(authors id) );
    $self->tb->ok(! -e $dir, 'Repository has no archives');

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

    $self->pinto->logger->log_handler->contains_ok($rx, $name);

    return;
}

#------------------------------------------------------------------------------

sub log_unlike {
    my ($self, $rx, $name) = @_;

    $name ||= 'Log output does not match';

    $self->pinto->logger->log_handler->does_not_contain_ok($rx, $name);

    return;
}

#------------------------------------------------------------------------------

sub populate {
    my ($self, @specs) = @_;

    for my $spec (@specs) {
        my $struct  = make_dist_struct($spec);
        my $archive = make_dist_archive($struct);

        my $args = { norecurse => 1,
                     archives  => $archive,
                     author    => $struct->{cpan_author} };

        my $r = $self->run_ok('Add', $args, "Populating repository with $spec");
        croak 'Population failed so the rest of this test is aborted' unless $r->is_success;
    }

    return $self;
}

#------------------------------------------------------------------------------

sub clear_cache {
    my ($self) = @_;

    $self->pinto->repos->clear_cache;

    return $self;
}

#------------------------------------------------------------------------------

sub parse_pkg_spec {
    my ($spec) = @_;

    # Remove all whitespace from spec
    $spec =~ s{\s+}{}g;

    # Spec looks like "AUTHOR/Foo-Bar-1.2/Foo::Bar-1.2/stack/+"
    my ($author, $dist_archive, $pkg, $stack_name, $is_pinned) = split m{/}x, $spec;

    # Spec must at least have these
    confess "Could not parse pkg spec: $spec"
       if not ($author and $dist_archive and $pkg);

    # Append the usual suffix to the archive
    $dist_archive .= '.tar.gz' unless $dist_archive =~ m{\.tar\.gz$}x;

    # Normalize the is_pinned flag
    $is_pinned = ($is_pinned eq '+' ? 1 : 0) if defined $is_pinned;

    # Parse package name/version
    my ($pkg_name, $pkg_version) = split m{-}x, $pkg;

    # Set defaults
    $stack_name  ||= 'default';
    $pkg_version ||= 0;

    return ($author, $dist_archive, $pkg_name, $pkg_version, $stack_name, $is_pinned);
}

#------------------------------------------------------------------------------

1;

__END__
