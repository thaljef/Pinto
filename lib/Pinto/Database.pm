# ABSTRACT: Interface to the Pinto database

package Pinto::Database;

use Moose;

use Try::Tiny;
use Path::Class;

use DBIx::Class::DeploymentHandler;

use Pinto::Schema;
use Pinto::Exception qw(throw);

use namespace::autoclean;

#-------------------------------------------------------------------------------

# VERSION

#-------------------------------------------------------------------------------
# Attributes

has schema => (
   is         => 'ro',
   isa        => 'Pinto::Schema',
   handles    => [ qw(txn_begin txn_commit txn_rollback) ],
   init_arg   => undef,
   builder    => '_build_schema',
   lazy       => 1,
);


has deployer => (
   is         => 'ro',
   isa        => 'DBIx::Class::DeploymentHandler',
   init_arg   => undef,
   builder    => '_build_deployer',
   lazy       => 1,
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

    my @args   = ($dsn, undef, undef, {on_connect_call => 'use_foreign_keys'});
    my $schema = Pinto::Schema->connect(@args);

    # Install our logger into the schema
    $schema->logger($self->logger);

    return $schema;
}

#-------------------------------------------------------------------------------

sub _build_deployer {

    my ($self) = @_;

    return DBIx::Class::DeploymentHandler->new( schema              => $self->schema,
                                                databases           => 'SQLite',
                                                script_directory    => $self->config->sql_dir->stringify,
                                                sql_translator_args => { add_drop_table => 0 } );
}

#-------------------------------------------------------------------------------

sub select_distributions {
    my ($self, $where, $attrs) = @_;

    $attrs ||= {};
    $attrs->{prefetch} ||= 'packages';

    return $self->schema->resultset('Distribution')->search($where, $attrs);
}

#-------------------------------------------------------------------------------

sub select_distribution {
    my ($self, $where, $attrs) = @_;

    $attrs ||= {};
    $attrs->{prefetch} ||= 'packages';
    $attrs->{key}      ||= 'author_canonical_archive_unique';

    return $self->schema->resultset('Distribution')->find($where, $attrs);
}

#-------------------------------------------------------------------------------

sub select_packages {
    my ($self, $where, $attrs) = @_;

    $attrs ||= {};
    $attrs->{prefetch} ||= 'distribution';

    return $self->schema->resultset('Package')->search($where, $attrs);
}

#-------------------------------------------------------------------------------

sub select_registration {
  my ($self, $where, $attrs) = @_;

  $attrs ||= {};
  $attrs->{prefetch} ||= [ {package => 'distribution'}, 'stack' ];

  return $self->schema->resultset('Registration')->find($where, $attrs);
}

#-------------------------------------------------------------------------------

sub select_registrations {
    my ($self, $where, $attrs) = @_;

    $attrs ||= {};
    $attrs->{prefetch} ||= [ qw( package stack ) ];

    return $self->schema->resultset('Registration')->search($where, $attrs);
}

#-------------------------------------------------------------------------------

sub create_distribution {
    my ($self, $struct) = @_;

    my $pretty_dist = "$struct->{author}/$struct->{archive}";
    $self->debug("Inserting distribution $pretty_dist into database");

    return $self->schema->resultset('Distribution')->create($struct);
}

#-------------------------------------------------------------------------------

sub select_stacks {
    my ($self, $where, $attrs) = @_;

    return $self->schema->resultset('Stack')->search( $where, $attrs );
}

#-------------------------------------------------------------------------------

sub select_stack {
    my ($self, $where, $attrs) = @_;

    $attrs ||= {};
    $attrs->{key} = 'name_canonical_unique';
    $where->{name_canonical} ||= lc delete $where->{name};

    return $self->schema->resultset('Stack')->find( $where, $attrs );
}

#-------------------------------------------------------------------------------

sub create_stack {
    my ($self, $attrs) = @_;

    return $self->schema->resultset('Stack')->create( $attrs );
}

#-------------------------------------------------------------------------------

sub select_revisions {
    my ($self, $where, $attrs) = @_;

    return $self->schema->resultset('Revision')->search( $where, $attrs );
}

#-------------------------------------------------------------------------------

sub create_revision {
    my ($self, $attrs) = @_;

    return $self->schema->resultset('Revision')->create( $attrs );
}

#-------------------------------------------------------------------------------

sub create_kommit {
    my ($self, $attrs) = @_;

    return $self->schema->resultset('Kommit')->create( $attrs );
}

#-------------------------------------------------------------------------------

sub repository_properties {
    my ($self) = @_;

    return $self->schema->resultset('RepositoryProperty');
}

#-------------------------------------------------------------------------------

sub deploy {
    my ($self) = @_;

    $self->mkpath( $self->config->db_dir() );
    $self->debug( 'Creating database at ' . $self->config->db_file );

    local $ENV{DBIC_NO_VERSION_CHECK} = 1;
    $self->deployer->prepare_install;
    $self->deployer->install;

    return $self;
}

#-------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#-------------------------------------------------------------------------------

1;

__END__
