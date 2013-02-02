# ABSTRACT: Interface to the Pinto database

package Pinto::Database;

use Moose;
use MooseX::MarkAsMethods (autoclean => 1);

use Pinto::Schema;

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
         Pinto::Role::Loggable );

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

    $self->config->db_dir->mkpath;
    $self->schema->deploy;

    return $self;
}

#-------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#-------------------------------------------------------------------------------

1;

__END__
