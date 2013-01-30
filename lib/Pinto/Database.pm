# ABSTRACT: Interface to the Pinto database

package Pinto::Database;

use Moose;

use Pinto::Schema;

use namespace::autoclean;

#-------------------------------------------------------------------------------

# VERSION

#-------------------------------------------------------------------------------
# Attributes

has schema => (
   is         => 'ro',
   isa        => 'Pinto::Schema',
   builder    => '_build_schema',
   init_arg   => undef,
   lazy       => 1,
);


has repo => (
   is         => 'ro',
   isa        => 'Pinto::Repository',
   weak_ref   => 1,
   required   => 1,
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

    my $schema = Pinto::Schema->new;

    my $db_file = $self->config->db_file;
    my $dsn     = "dbi:SQLite:$db_file";
    my $xtra    = {on_connect_call => 'use_foreign_keys'};
    my @args    = ($dsn, undef, undef, $xtra);

    my $connected = $schema->connect(@args);

    # Inject attributes thru back door
    $connected->logger($self->logger);
    $connected->repo($self->repo);

    return $connected;
}

#-------------------------------------------------------------------------------

sub deploy {
    my ($self) = @_;

    $self->mkpath( $self->config->db_dir );
    $self->schema->deploy;

    return $self;
}

#-------------------------------------------------------------------------------

sub select_distribution {
    my ($self, $where, $attrs) = @_;

    $attrs ||= {};
    $attrs->{prefetch} ||= 'packages';
    $attrs->{key}      ||= 'author_canonical_archive_unique';

    return $self->schema->distribution_rs->find($where, $attrs);
}

#-------------------------------------------------------------------------------

sub select_packages {
    my ($self, $where, $attrs) = @_;

    $attrs ||= {};
    $attrs->{prefetch} ||= 'distribution';

    return $self->schema->package_rs->search($where, $attrs);
}

#-------------------------------------------------------------------------------

sub select_stacks {
    my ($self, $where, $attrs) = @_;

    return $self->schema->stack_rs->search( $where, $attrs );
}

#-------------------------------------------------------------------------------

sub select_stack {
    my ($self, $where, $attrs) = @_;

    $attrs ||= {};
    $attrs->{key} = 'name_canonical_unique';
    $where->{name_canonical} ||= lc delete $where->{name};

    return $self->schema->stack_rs->find( $where, $attrs );
}

#-------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#-------------------------------------------------------------------------------

1;

__END__
