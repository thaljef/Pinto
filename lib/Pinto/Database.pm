# ABSTRACT: Interface to the Pinto database

package Pinto::Database;

use Moose;

use Carp;
use Try::Tiny;
use Path::Class;

use Pinto::Schema;
use Pinto::IndexWriter;

use namespace::autoclean;

#-------------------------------------------------------------------------------

# VERSION

#-------------------------------------------------------------------------------
# Attributes

has schema => (
   is         => 'ro',
   isa        => 'Pinto::Schema',
   init_arg   => undef,
   lazy_build => 1,
);

#-------------------------------------------------------------------------------
# Roles

with qw( Pinto::Role::Configurable
         Pinto::Role::Loggable
         Pinto::Role::PathMaker );

#-------------------------------------------------------------------------------
# Builders

sub _build_schema {
    my ($self) = @_;
    my $db_file = $self->config->db_file();
    my $dsn = "dbi:SQLite:$db_file";

    my $connection;
    try   { $connection = Pinto::Schema->connect($dsn) }
    catch { confess "Database error: $_" };

    return $connection;
}

#-------------------------------------------------------------------------------
# Convenience methods

sub select_distributions {
    my ($self, $where, $attrs) = @_;

    $where ||= {};
    $attrs ||= {prefetch => 'packages'};

    return $self->schema->resultset('Distribution')->search($where, $attrs);
}

#-------------------------------------------------------------------------------

sub select_packages {
    my ($self, $where, $attrs) = @_;

    $where ||= {};
    $attrs ||= {prefetch => 'distribution'};

    return $self->schema->resultset('Package')->search($where, $attrs);
}

#-------------------------------------------------------------------------------

sub select_package_stacks {
    my ($self, $where, $attrs) = @_;

    $where ||= {};
    $attrs ||= { pefetch => [ qw( package stack pin ) ] };

    return $self->schema->resultset('PackageStack')->search($where, $attrs);
}

#-------------------------------------------------------------------------------

sub create_distribution {
    my ($self, $struct) = @_;

    $self->debug("Inserting distribution $struct->{path} into database");

    return $self->schema->resultset('Distribution')->create($struct);
}

#-------------------------------------------------------------------------------

sub delete_distribution {
    my ($self, $dist) = @_;

    $self->debug("Deleting distribution $dist from database");

    return $dist->delete();
}

#-------------------------------------------------------------------------------

sub register {
    my ($self, $pkg, $stack) = @_;

    if (my $pkg_stack = $pkg->packages_stack_rs->find( {stack => $stack} ) ) {
        $self->debug("Package $pkg is already on stack $stack");
        return 0;
    }

    my $attrs     = { join => [ qw(package stack) ] };
    my $where     = { 'package.name' => $pkg->name, 'stack' => $stack->id };
    my $incumbent = $self->select_package_stacks($where, $attrs)->single;

    if (not $incumbent) {
        $self->debug("Registering $pkg on stack $stack");
        $self->create_pkg_stack( {package => $pkg, stack => $stack} );
        return 1;
    }

    my $incumbent_pkg = $incumbent->package;

    if ( $incumbent_pkg == $pkg ) {
        $self->warning("Package $pkg is already on stack $stack");
        return 0;
    }

    if ( $incumbent_pkg < $pkg and $incumbent->is_pinned() ) {
        my $pkg_name = $pkg->name();
        $self->error("Cannot add $pkg to stack $stack because $pkg_name is pinned to $incumbent_pkg");
        return 0;
    }


    my ($log_as, $direction) = ($incumbent_pkg > $pkg) ? ('warning', 'Downgrading')
                                                       : ('notice',  'Upgrading');

    $incumbent->delete();
    $self->$log_as("$direction package $incumbent_pkg to $pkg in stack $stack");
    $self->create_pkg_stack( {package => $pkg, stack => $stack} );

    # TODO: Maybe return -1 if downgraded, +1 if upgraded.  Or maybe return
    # the new pkg_stk and the incumbent so caller can inspect them.

    return 1;
}

#-------------------------------------------------------------------------------

sub pin {
    my ($self, $pkg, $stack) = @_;

    my $where = {stack => $stack->id};
    my $pkg_stk = $pkg->search_related('packages_stack', $where)->single;

    confess "Package $pkg is not on stack $stack"
        if not $pkg_stk;

    $self->warning("Package $pkg is already pinned on stack $stack")
        and return 0 if $pkg_stk->is_pinned;

    $pkg_stk->update( {is_pinned => 1} );

    return 1;
}


#-------------------------------------------------------------------------------

sub unpin {
    my ($self, $pkg, $stack) = @_;

    my $where = {stack => $stack->id};
    my $pkg_stk = $pkg->search_related('packages_stack', $where)->single;

    confess "Package $pkg is not on stack $stack"
        if not $pkg_stk;

    $self->warning("Package $pkg is not pinned on $stack")
        and return 0 unless $pkg_stk->is_pinned;

    $pkg_stk->update( {is_pinned => 0} );

    return 1;
}

#-------------------------------------------------------------------------------

sub create_pkg_stack {
    my ($self, $attrs) = @_;

    my $pkg_stack = $self->schema->resultset('PackageStack')->create( $attrs );

    return $pkg_stack;

}

#-------------------------------------------------------------------------------

sub create_pin {
    my ($self, $attrs) = @_;

    my $pin = $self->schema->resultset('Pin')->create( $attrs );

    return $pin;
}

#-------------------------------------------------------------------------------

sub select_stacks {
    my ($self, $where, $attrs) = @_;

    $where ||= {};
    $attrs ||= {};

    my $stack = $self->schema->resultset('Stack')->search( $where, $attrs );

    return $stack;
}

#-------------------------------------------------------------------------------

sub create_stack {
    my ($self, $attrs) = @_;

    my $stack = $self->schema->resultset('Stack')->create( $attrs );

    return $stack;
}

#-------------------------------------------------------------------------------

sub write_index {
    my ($self) = @_;

    my $writer = Pinto::IndexWriter->new( logger => $self->logger(),
                                          db     => $self );

    my $index_file = $self->config->index_file();
    $writer->write(file => $index_file);

    return $self;
}

#-------------------------------------------------------------------------------

sub deploy {
    my ($self) = @_;

    $self->mkpath( $self->config->db_dir() );
    $self->debug( 'Creating database at ' . $self->config->db_file() );
    $self->schema->deploy();

    return $self;
}

#-------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#-------------------------------------------------------------------------------

1;

__END__
