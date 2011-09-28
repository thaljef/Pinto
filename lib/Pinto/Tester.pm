package Pinto::Tester;

# ABSTRACT: A class for testing a Pinto repository

use Moose;
use MooseX::NonMoose;

use Path::Class;

use Pinto;
use Pinto::Util;
use Pinto::Creator;
use Pinto::Types qw(Dir);

extends 'Test::Builder::Module';

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

has pinto => (
    is       => 'ro',
    isa      => 'Pinto',
    required => 1,
);


has repos => (
   is       => 'ro',
   isa      => Dir,
   init_arg => undef,
   default  => sub { $_[0]->pinto->config->repos() },
   lazy     => 1,
);


has tb => (
   is       => 'ro',
   isa      => 'Test::Builder',
   init_arg => undef,
   default  => => sub { __PACKAGE__->builder() },
);

#------------------------------------------------------------------------------

sub BUILDARGS {
    my ($class, $creator_args, $pinto_args) = @_;

    my $repos   = dir( File::Temp::tempdir(CLEANUP => 1) );
    my $creator = Pinto::Creator->new(repos => $repos);
    $creator->create( %{ $creator_args } );

    my $pinto = Pinto->new(repos => $repos, %{$pinto_args});

    return {pinto => $pinto};
}

#------------------------------------------------------------------------------

sub path_exists_ok {
    my ($self, $path, $name) = @_;

    $path = file( $self->repos(), @{$path} );
    $name ||= "$path exists";

    return $self->tb->ok(-e $path, $name);
}

#------------------------------------------------------------------------------

sub path_not_exists_ok {
    my ($self, $path, $name) = @_;

    $path = file( $self->repos(), @{$path} );
    $name ||= "$path does not exist";

    return $self->tb->ok(! -e $path, $name);
}

#------------------------------------------------------------------------------

sub dist_exists_ok {
    my ($self, $dist_basename, $author, $test_name) = @_;

    my $author_dir = Pinto::Util::author_dir($self->repos(), qw(authors id), $author);
    my $dist_path = $author_dir->file($dist_basename);
    $test_name ||= "Distribution $dist_path exists in repository";

    return $self->tb->ok(-e $dist_path, $test_name);
}

#------------------------------------------------------------------------------

sub dist_not_exists_ok {
    my ($self, $dist_basename, $author, $test_name) = @_;

    my $author_dir = Pinto::Util::author_dir($self->repos(), qw(authors id), $author);
    my $dist_path = $author_dir->file($dist_basename);
    $test_name ||= "Distribution $dist_path does not exist in repository";

    return $self->tb->ok(! -e $dist_path, $test_name);
}

#------------------------------------------------------------------------------

sub package_is_latest_ok {
    my ($self, $pkg_name, $dist_basename, $author) = @_;

    my $author_dir = Pinto::Util::author_dir($author);
    my $dist_path = $author_dir->file($dist_basename)->as_foreign('Unix');

    my $where = { name => $pkg_name, 'distribution.path' => $dist_path };
    my $pkg = $self->pinto->db->get_all_packages($where)->single();

    return $self->tb->ok(0, "$pkg_name -- $dist_path is not loaded at all") if not $pkg;
    return $self->tb->is_eq($pkg->is_latest(), 1, "$pkg_name -- $dist_path is the latest");
}

#------------------------------------------------------------------------------

sub package_not_latest_ok {
    my ($self, $pkg_name, $dist_basename, $author) = @_;

    my $author_dir = Pinto::Util::author_dir($author);
    my $dist_path = $author_dir->file($dist_basename)->as_foreign('Unix');

    my $where = { name => $pkg_name, 'distribution.path' => $dist_path };
    my $pkg = $self->pinto->db->get_all_packages($where)->single();

    return $self->tb->ok(0, "$pkg_name -- $dist_path is not loaded at all") if not $pkg;
    return $self->tb->is_eq($pkg->is_latest(), undef, "$pkg_name -- $dist_path is not the latest");
}

#------------------------------------------------------------------------------

sub package_loaded_ok {
    my ($self, $pkg_name, $dist_basename, $author, $version) = @_;

    my $author_dir = Pinto::Util::author_dir($author);
    my $dist_path = $author_dir->file($dist_basename)->as_foreign('Unix');

    my $where = { name => $pkg_name, 'distribution.path' => $dist_path };
    my $pkg = $self->pinto->db->get_all_packages($where)->single();
    return $self->tb->ok(0, "$pkg_name -- $dist_path is not loaded at all") if not $pkg;

    $self->tb->ok(1, "$pkg_name -- $dist_path is loaded");
    $self->tb->is_eq($pkg->author(), $author,  "$pkg_name has correct author");
    $self->tb->is_eq($pkg->version(), $version, "$pkg_name has correct version");
    return 1;
}

#------------------------------------------------------------------------------

sub package_not_loaded_ok {
    my ($self, $pkg_name, $dist_basename, $author) = @_;

    my $author_dir = Pinto::Util::author_dir($author);
    my $dist_path = $author_dir->file($dist_basename)->as_foreign('Unix');

    my $where = { name => $pkg_name, 'distribution.path' => $dist_path };
    my $pkg = $self->pinto->db->get_all_packages($where)->single();

    return $self->tb->ok(0, "$pkg_name -- $dist_path is still loaded") if $pkg;

    return $self->tb->ok(1, "$pkg_name -- $dist_path is not loaded");
}

#------------------------------------------------------------------------------

sub result_ok {
    my ($self, $result) = @_;

    return 1 if $self->tb->ok( $result->is_success(), 'Result was succesful' );
    $self->tb->diag( "Diagnostics: " . $result->to_string() );
    return 0;
}

#------------------------------------------------------------------------------

sub result_not_ok {
    my ($self, $result) = @_;

    return $self->tb->ok( !$result->is_success(), 'Result was not succesful' );
}

#------------------------------------------------------------------------------

1;

__END__
