package Pinto::Database;

# ABSTRACT: Interface to the Pinto database

use Moose;

use Try::Tiny;
use Path::Class;

use Pinto::Schema;
use Pinto::IndexWriter;
use Pinto::Exceptions qw(throw_fatal throw_error);

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

with qw( Pinto::Interface::Configurable
         Pinto::Interface::Loggable
         Pinto::Role::PathMaker );

#-------------------------------------------------------------------------------
# Builders

sub _build_schema {
    my ($self) = @_;
    my $db_file = $self->config->db_file();
    my $dsn = "dbi:SQLite:$db_file";

    my $connection;
    try   { $connection = Pinto::Schema->connect($dsn) }
    catch { throw_fatal "Database error: $_" };

    return $connection;
}

#-------------------------------------------------------------------------------
# Convenience methods

sub select_distributions {
    my ($self, $where, $attrs) = @_;

    $where ||= {};
    $attrs ||= {};

    return $self->schema->resultset('Distribution')->search($where, $attrs);
}

#-------------------------------------------------------------------------------

sub select_packages {
    my ($self, $where, $attrs) = @_;

    $where ||= {};
    $attrs ||= {};

    return $self->schema->resultset('Package')->search($where, $attrs);
}

#-------------------------------------------------------------------------------

sub select_package_stack {
    my ($self, $where, $attrs) = @_;

    $where ||= {};
    $attrs ||= { pefetch => [ qw( package stack pin ) ] };

    return $self->schema->resultset('PackageStack')->search($where, $attrs);
}

#-------------------------------------------------------------------------------

sub create_distribution {
    my ($self, $dist_struct, $stack, $pin) = @_;

    $self->debug("Inserting distribution $dist_struct->{path} into database");

    my $txn_guard = $self->schema->txn_scope_guard(); # BEGIN transaction

    my $dist = $self->schema->resultset('Distribution')->create($dist_struct);

    # TODO: Decide if the distinction between developer/release
    # distributions really makes sense.  Now that we have stacks,
    # we might not really need to make this distinction.
    $self->whine("Developer distribution $dist will not be indexed")
        if $dist->is_devel() and not $self->config->devel();

    for my $pkg ( $dist->packages() ) {
        # If the registration fails, then it cannot be pinned
        # TODO: Throw exception instead of jumping to next $pkg ?
        my $pkg_stack = $self->register($pkg, $stack) or next;
        $pkg_stack->pin($pin) && $pkg_stack->update() if $pin;
    }

    $txn_guard->commit(); #END transaction

    return $dist;
}

#-------------------------------------------------------------------------------

sub delete_distribution {
    my ($self, $dist) = @_;

    $self->debug("Deleting distribution $dist from database");

    my $txn_guard = $self->schema->txn_scope_guard(); # BEGIN transaction

    $dist->delete();

    $txn_guard->commit(); # END transaction

    return $self;
}

#-------------------------------------------------------------------------------

sub register {
    my ($self, $pkg, $stack) = @_;

    my $attrs     = { join => [ qw(package stack) ] };
    my $where     = { 'package.name' => $pkg->name(), 'stack' => $stack->id() };
    my $incumbent = $self->select_package_stack( $where, $attrs )->single();

    if (not $incumbent) {
        $self->debug("Adding $pkg to stack $stack");
        my $pkg_stack = $self->create_pkg_stack( {package => $pkg, stack => $stack} );
        return $pkg_stack;
    }

    my $incumbent_pkg = $incumbent->package();

    if ( $incumbent_pkg == $pkg ) {
        $self->whine("Package $pkg is already in stack $stack");
        return;
    }

    if ($incumbent_pkg > $pkg) {
        $self->whine("Stack $stack already contains newer package $pkg");
        return;
    }

    if ( $incumbent_pkg < $pkg and $incumbent->is_pinned() ) {
        my $name = $pkg->name();
        $self->whine("Can't add $pkg to stack $stack because $name is pinned to $incumbent_pkg");
        return;
    }

    # If we get here, then we know that the incoming package is newer
    # than the incumbent, and the incumbent is not pinned.  So we can
    # go ahead and register it in this stack.

    $incumbent->delete();
    $self->info("Upgrading package $incumbent to $pkg in stack $stack");
    my $pkg_stack = $self->create_pkg_stack( {package => $pkg, stack => $stack} );

    return $pkg_stack;
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

sub select_stack {
    my ($self, $where, $attrs) = @_;

    $where ||= {};
    $attrs ||= {};

    my $stack = $self->schema->resultset('Stack')->find( $where, $attrs );

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
