package Pinto::Tester;

# ABSTRACT: A class for testing a Pinto repository

use Moose;
use MooseX::NonMoose;

use Path::Class;

use Pinto;
use Pinto::Util;
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
    my ($self, $author, $basename, $name) = @_;
    my $repos = $self->repos();
    my $author_dir = Pinto::Util::author_dir($repos, qw(authors id), $author);
    my $dist_path = $author_dir->file($basename);
    $name ||= "Distribution $dist_path exists in repository";
    return $self->tb->ok(-e $dist_path, $name);
}

#------------------------------------------------------------------------------

sub dist_not_exists_ok {
    my ($self, $author, $basename, $name) = @_;
    my $repos = $self->repos();
    my $author_dir = Pinto::Util::author_dir($repos, qw(authors id), $author);
    my $dist_path = $author_dir->file($basename);
    $name ||= "Distribution $dist_path does not exist in repository";
    return $self->tb->ok(! -e $dist_path, $name);
}

#------------------------------------------------------------------------------

sub package_indexed_ok {
    my ($self, $name, $author, $version) = @_;
    my $pkg = $self->pinto->_idxmgr->master_index->packages->{$name};
    return $self->tb->ok(0, "Package $name is not indexed") if not $pkg;

    my $dist = $pkg->dist();
    $self->tb->ok($pkg, "Package $name is in the index");
    $self->tb->is_eq($dist->author(), $author,  "Package $name has correct author");
    $self->tb->is_eq($pkg->version(), $version, "Package $name has correct version");
    return 1;
}

#------------------------------------------------------------------------------

sub package_not_indexed_ok {
    my ($self, $name) = @_;
    my $pkg = $self->pinto->_idxmgr->master_index->packages->{$name};
    return $self->tb->ok(0, "Package $name is indexed") if $pkg;
    return $self->tb->ok(1, "Package $name is not indexed" );
}

#------------------------------------------------------------------------------

1;

__END__
