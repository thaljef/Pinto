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

    my $schema;
    try   { $schema = Pinto::Schema->connect($dsn) }
    catch { throw "Database connection error: $_" };

    # Install our logger into the schema
    $schema->logger($self->logger);

    return $schema;
}

#-------------------------------------------------------------------------------

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

sub select_stacks {
    my ($self, $where, $attrs) = @_;

    $where ||= {};
    $attrs ||= {};

    my $stack = $self->schema->resultset('Stack')->search( $where, $attrs );

    return $stack;
}

#-------------------------------------------------------------------------------

sub select_stack {
    my ($self, $where, $attrs) = @_;

    $attrs ||= {};
    $attrs->{key} = 'name_unique';

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
    $self->schema->deploy;

    return $self;
}

#-------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#-------------------------------------------------------------------------------

1;

__END__
