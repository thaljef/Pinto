package Pinto::Tester;

# ABSTRACT: A class for testing a Pinto repository

use Moose;
use MooseX::NonMoose;
use MooseX::Types::Moose qw(ScalarRef HashRef);

use Carp;
use IO::String;
use Path::Class;
use Test::Log::Dispatch;

use Pinto;
use Pinto::Util;
use Pinto::Creator;
use Pinto::Types qw(Dir);

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
   default  => sub { dir( File::Temp::tempdir(CLEANUP => 1) ) },
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

sub package_loaded_ok {
    my ($self, $pkg_spec, $latest) = @_;

    my ($author, $dist_file, $pkg_name, $pkg_ver) = parse_pkg_spec($pkg_spec);

    my $author_dir = Pinto::Util::author_dir($author);
    my $dist_path = $author_dir->file($dist_file)->as_foreign('Unix');

    my $attrs = { prefetch  => 'distribution' };
    my $where = { name => $pkg_name, 'distribution.path' => $dist_path };
    my $pkg = $self->pinto->repos->db->select_packages($where, $attrs)->single();
    return $self->tb->ok(0, "$pkg_spec is not loaded at all") if not $pkg;

    $self->tb->ok(1, "$pkg_spec is loaded");
    $self->tb->is_eq($pkg->version(), $pkg_ver, "$pkg_name has correct version");

    my $archive = $pkg->distribution->archive( $self->root() );
    $self->tb->ok(-e $archive, "Archive $archive exists");

    $self->tb->is_eq( $pkg->is_latest(), 1, "$pkg_spec is latest" )
        if $latest;

    $self->tb->is_eq( $pkg->is_latest(), undef, "$pkg_spec is not latest" )
        if not $latest;

    return;
}

#------------------------------------------------------------------------------

sub package_not_loaded_ok {
    my ($self, $pkg_spec) = @_;

    my ($author, $dist_file, $pkg_name, $pkg_ver) = parse_pkg_spec($pkg_spec);

    my $author_dir = Pinto::Util::author_dir($author);
    my $dist_path = $author_dir->file($dist_file)->as_foreign('Unix');
    my $archive   = $self->root()->file(qw(authors id), $author_dir, $dist_file);

    my $attrs = { prefetch  => 'distribution' };
    my $where = { name => $pkg_name, 'distribution.path' => $dist_path };
    my $pkg = $self->pinto->repos->select_packages($where, $attrs)->single();

    $self->tb->ok(!$pkg, "$pkg_spec is still loaded");

    $self->tb->ok(! -e $archive, "Archive $archive still exists");

    return;
}

#------------------------------------------------------------------------------

sub result_ok {
    my ($self, $result) = @_;

    $self->tb->ok( $result->is_success(), 'Result was succesful' )
        || $self->tb->diag( "Diagnostics: " . $result->to_string() );

    return;
}

#------------------------------------------------------------------------------

sub result_not_ok {
    my ($self, $result) = @_;

    $self->tb->ok( !$result->is_success(), 'Result was not succesful' );

    return;
}

#------------------------------------------------------------------------------

sub repository_empty_ok {
    my ($self) = @_;

    my @dists = $self->pinto->repos->select_distributions()->all();
    $self->tb->is_eq(scalar @dists, 0, 'Database has no distributions');

    my @pkgs = $self->pinto->repos->select_packages()->all();
    $self->tb->is_eq(scalar @pkgs, 0, 'Database has no packages');

    my $dir = dir( $self->root(), qw(authors id) );
    $self->tb->ok(! -e $dir, 'Repository has no archives');

    return;
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

sub parse_pkg_spec {
    my ($spec) = @_;

    # Looks like "AUTHOR/Foo-1.2.tar.gz/Foo::Bar-1.2"
    $spec =~ m{ ^ ([^/]+) / ([^/]+) / ([^-]+) - (.+) $ }mx
        or croak "Could not parse pkg spec: $spec";

    # TODO: use sexy named captures instead
    my ($author, $dist_file, $pkg_name, $pkg_ver) = ($1, $2, $3, $4);

    return ($author, $dist_file, $pkg_name, $pkg_ver);
}

#------------------------------------------------------------------------------

1;

__END__
