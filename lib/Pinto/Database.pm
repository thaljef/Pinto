# ABSTRACT: Interface to the Pinto database

package Pinto::Database;

use Moose;

use Try::Tiny;
use Path::Class;

use Pinto::Schema;
use Pinto::IndexWriter;
use Pinto::Exception qw(throw);

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
    catch { throw "Database connection error: $_" };

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

sub select_registry {
  my ($self, $where, $attrs) = @_;

  $attrs ||= {};
  $attrs->{key} = 'stack_name_unique';

  return $self->schema->resultset('Registry')->find($where, $attrs);
}

#-------------------------------------------------------------------------------

sub select_registries {
    my ($self, $where, $attrs) = @_;

    $where ||= {};
    $attrs ||= { pefetch => [ qw( package stack pin ) ] };

    return $self->schema->resultset('Registry')->search($where, $attrs);
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
    my ($self, $dist, $stack) = @_;

    my $errors = 0;
    my $did_register = 0;

    for my $pkg ($dist->packages) {

      if ($pkg->registries_rs->find( {stack => $stack->id} ) ) {
        $self->debug("Package $pkg is already on stack $stack");
        return 0;
      }

      my $attrs     = { prefetch => 'package' };
      my $where     = { name => $pkg->name, stack => $stack->id };
      my $incumbent = $self->select_registry($where, $attrs);

      if (not $incumbent) {
        $self->debug("Registering $pkg on stack $stack");
        $self->create_registry( {package => $pkg, stack => $stack->id} );
        $did_register++;
        next;
      }

      my $incumbent_pkg = $incumbent->package;

      if ( $incumbent_pkg == $pkg ) {
        $self->warning("Package $pkg is already on stack $stack");
        next;
      }

      if ( $incumbent_pkg < $pkg and $incumbent->is_pinned ) {
        my $pkg_name = $pkg->name;
        $self->error("Cannot add $pkg to stack $stack because $pkg_name is pinned to $incumbent_pkg");
        $errors++;
        next;
      }


      my ($log_as, $direction) = ($incumbent_pkg > $pkg) ? ('warning', 'Downgrading')
                                                         : ('notice',  'Upgrading');

      $incumbent->delete;
      $self->$log_as("$direction package $incumbent_pkg to $pkg in stack $stack");
      $self->create_registry( {package => $pkg, stack => $stack} );
      $did_register++;
    }

    throw "Unable to register distribution $dist on stack $stack"
      if $errors;

    $stack->touch if $did_register; # Update mtime

    return $did_register;
}

#-------------------------------------------------------------------------------

sub pin {
    my ($self, $dist, $stack) = @_;

    my $where  = {stack => $stack->id};
    my $errors  = 0;
    my $did_pin = 0;

    for my $pkg ($dist->packages) {
        my $registry = $pkg->search_related('registries', $where)->single;

        if (not $registry) {
            $self->error("Package $pkg is not on stack $stack");
            $errors++;
            next;
        }


        if ($registry->is_pinned) {
            $self->warning("Package $pkg is already pinned on stack $stack");
            next;
        }

        $registry->update( {is_pinned => 1} );
        $did_pin++;
    }

    throw "Unable to pin distribution $dist to stack $stack"
      if $errors;

    $stack->touch if $did_pin; # Update mtime

    return $did_pin;

}


#-------------------------------------------------------------------------------

sub unpin {
    my ($self, $dist, $stack) = @_;

    my $where = {stack => $stack->id};
    my $did_unpin = 0;

    for my $pkg ($dist->packages) {
        my $registry = $pkg->search_related('registries', $where)->single;

        if (not $registry) {
            $self->warning("Package $pkg is not on stack $stack");
            next;
        }

        if (not $registry->is_pinned) {
            $self->warning("Package $pkg is not pinned on stack $stack");
            next;
        }

        $registry->update( {is_pinned => 0} );
        $did_unpin++;
    }

    $stack->touch if $did_unpin; # Update mtime

    return $did_unpin;
}

#-------------------------------------------------------------------------------

sub create_registry {
    my ($self, $attrs) = @_;

    my $registry = $self->schema->resultset('Registry')->create( $attrs );

    return $registry;

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
