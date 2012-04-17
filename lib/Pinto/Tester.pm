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

use Pinto;
use Pinto::Util;
use Pinto::Creator;
use Pinto::Tester::Util qw(make_dist_struct make_dist_archive);
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
   default  => sub { dir( tempdir(CLEANUP => 1) ) },
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

sub action_ok {
    my ($self, $action, $batch_args, $action_args) = @_;

    $self->pinto->new_batch( %{ $batch_args || {} } );
    $self->pinto->add_action($action, %{ $action_args || {} } );
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    $self->result_ok( $self->pinto->run_actions() );
}

#------------------------------------------------------------------------------

sub package_ok {
    my ($self, $pkg_spec) = @_;

    my ($author, $dist_archive, $pkg_name, $pkg_ver, $stack_name)
        = parse_pkg_spec($pkg_spec);

    my $pkg = $self->pinto->repos->get_stack_member(package => $pkg_name, stack => $stack_name);
    return $self->tb->ok(0, "$pkg_spec is not loaded at all") if not $pkg;

    $self->tb->ok(1, "$pkg_spec is loaded");
    $self->tb->is_eq($pkg->package->version(), $pkg_ver, "$pkg_name has correct version");

    my $author_dir = Pinto::Util::author_dir($author);
    my $dist_path = $author_dir->file($dist_archive)->as_foreign('Unix');
    $self->tb->is_eq($pkg->package->distribution->path(), $dist_path, "$pkg_name has correct dist path");

    my $archive = $pkg->package->distribution->archive( $self->root() );
    $self->tb->ok(-e $archive, "Archive $archive exists");

    $self->path_exists_ok( [qw(authors id), $author_dir, 'CHECKSUMS'] );

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

sub populate {
    my ($self, @specs) = @_;

    $self->pinto->new_batch();

    for my $spec (@specs) {
        my $struct  = make_dist_struct($spec);
        my $archive = make_dist_archive($struct);
        my %action_args = (author => $struct->{cpan_author}, norecurse => 1, archive => $archive);
        $self->pinto->add_action( 'Add', %action_args );
    }

    $self->result_ok( $self->pinto->run_actions() );

    return $self;
}

#------------------------------------------------------------------------------

sub parse_pkg_spec {
    my ($spec) = @_;

    # Remove all whitespace from spec
    $spec =~ s{\s+}{}g;

    # Spec looks like "AUTHOR/Foo-Bar-1.2/Foo::Bar-1.2/stack"
    my ($author, $dist_archive, $pkg, $stack_name) = split m{/}x, $spec;

    # Spec must at least have these
    croak "Could not parse pkg spec: $spec"
       if not ($author and $dist_archive and $pkg);

    # Append the usual suffix to the archive
    $dist_archive .= '.tar.gz' unless $dist_archive =~ m{\.tar\.gz$}x;

    # Parse package name/version
    my ($pkg_name, $pkg_version) = split m{-}x, $pkg;

    # Set defaults
    $stack_name  ||= 'default';
    $pkg_version ||= 0;

    return ($author, $dist_archive, $pkg_name, $pkg_version, $stack_name);
}

#------------------------------------------------------------------------------

1;

__END__
