package Pinto::Tester;

# ABSTRACT: A class for testing a Pinto repository

use Moose;
use MooseX::NonMoose;
use IO::String;

use Path::Class;

use Pinto;
use Pinto::Util;
use Pinto::Creator;
use Pinto::Types qw(Dir);
use MooseX::Types::Moose qw(ScalarRef HashRef);

extends 'Test::Builder::Module';

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

has pinto_args => (
   is         => 'ro',
   isa        => HashRef,
   default    => sub { {} },
   auto_deref => 1,
);


has creator_args => (
   is         => 'ro',
   isa        => HashRef,
   default    => sub { {} },
   auto_deref => 1,
);


has pinto => (
    is       => 'ro',
    isa      => 'Pinto',
    builder  => '_build_pinto',
    lazy     => 1,
);


has root_dir => (
   is       => 'ro',
   isa      => Dir,
   default  => sub { dir( File::Temp::tempdir(CLEANUP => 1) ) },
);


has buffer => (
   is         => 'ro',
   isa        => ScalarRef,
   default    => sub { \my $buffer },
   writer     => '_set_buffer',
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

    my $creator = Pinto::Creator->new( root_dir => $self->root_dir() );
    $creator->create( $self->creator_args() );

    my %defaults = (out => $self->buffer(), verbose => 3, root_dir => $self->root_dir());

    return Pinto->new(%defaults, $self->pinto_args());
}
#------------------------------------------------------------------------------

sub bufferstr {
    my ($self)  = @_;

    return ${ $self->buffer() };
}

#------------------------------------------------------------------------------

sub reset_buffer {
    my ($self, $new_buffer) = @_;

    $new_buffer ||= \my $buffer;
    my $io = IO::String->new( ${$new_buffer} );
    $self->pinto->logger->{out} = $io; # Hack!
    $self->_set_buffer($new_buffer);

    return $self;
}

#------------------------------------------------------------------------------

sub path_exists_ok {
    my ($self, $path, $name) = @_;

    $path = file( $self->root_dir(), @{$path} );
    $name ||= "$path exists";

    return $self->tb->ok(-e $path, $name);
}

#------------------------------------------------------------------------------

sub path_not_exists_ok {
    my ($self, $path, $name) = @_;

    $path = file( $self->root_dir(), @{$path} );
    $name ||= "$path does not exist";

    return $self->tb->ok(! -e $path, $name);
}

#------------------------------------------------------------------------------

sub dist_exists_ok {
    my ($self, $dist_basename, $author, $test_name) = @_;

    my $author_dir = Pinto::Util::author_dir($self->root_dir(), qw(authors id), $author);
    my $dist_path = $author_dir->file($dist_basename);
    $test_name ||= "Distribution $dist_path exists in repository";

    return $self->tb->ok(-e $dist_path, $test_name);
}

#------------------------------------------------------------------------------

sub dist_not_exists_ok {
    my ($self, $dist_basename, $author, $test_name) = @_;

    my $author_dir = Pinto::Util::author_dir($self->root_dir(), qw(authors id), $author);
    my $dist_path = $author_dir->file($dist_basename);
    $test_name ||= "Distribution $dist_path does not exist in repository";

    return $self->tb->ok(! -e $dist_path, $test_name);
}

#------------------------------------------------------------------------------

sub package_is_latest_ok {
    my ($self, $pkg_name, $dist_basename, $author) = @_;

    my $author_dir = Pinto::Util::author_dir($author);
    my $dist_path = $author_dir->file($dist_basename)->as_foreign('Unix');

    my $attrs = { prefetch  => 'distribution' };
    my $where = { name => $pkg_name, 'distribution.path' => $dist_path };
    my $pkg = $self->pinto->repos->db->select_packages($where, $attrs)->single();

    return $self->tb->ok(0, "$pkg_name -- $dist_path is not loaded at all") if not $pkg;
    return $self->tb->is_eq($pkg->is_latest(), 1, "$pkg_name -- $dist_path is the latest");
}

#------------------------------------------------------------------------------

sub package_not_latest_ok {
    my ($self, $pkg_name, $dist_basename, $author) = @_;

    my $author_dir = Pinto::Util::author_dir($author);
    my $dist_path = $author_dir->file($dist_basename)->as_foreign('Unix');

    my $attrs = { prefetch  => 'distribution' };
    my $where = { name => $pkg_name, 'distribution.path' => $dist_path };
    my $pkg = $self->pinto->repos->db->select_packages($where, $attrs)->single();

    return $self->tb->ok(0, "$pkg_name -- $dist_path is not loaded at all") if not $pkg;
    return $self->tb->is_eq($pkg->is_latest(), undef, "$pkg_name -- $dist_path is not the latest");
}

#------------------------------------------------------------------------------

sub package_loaded_ok {
    my ($self, $pkg_name, $dist_basename, $author, $version) = @_;

    my $author_dir = Pinto::Util::author_dir($author);
    my $dist_path = $author_dir->file($dist_basename)->as_foreign('Unix');

    my $attrs = { prefetch  => 'distribution' };
    my $where = { name => $pkg_name, 'distribution.path' => $dist_path };
    my $pkg = $self->pinto->repos->db->select_packages($where, $attrs)->single();
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

    my $attrs = { prefetch  => 'distribution' };
    my $where = { name => $pkg_name, 'distribution.path' => $dist_path };
    my $pkg = $self->pinto->repos->db->select_packages($where, $attrs)->single();

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
