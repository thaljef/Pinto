# ABSTRACT: Migrate an existing Pinto repository to a new version

package Pinto::Migrator;

use Moose;

use Pinto;
use Pinto::Exception qw(throw);

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

with qw( Pinto::Role::Configurable
	     Pinto::Role::Loggable );

#------------------------------------------------------------------------------


sub migrate {
    my ($self) = @_;

    my $pinto = Pinto->new(root => $self->config->root);

    my $db_version = $pinto->repo->db->get_version;
    my $schema_version = $pinto->repo->db->schema->schema_version;

    die "This repository is too old to migrate\n"
      if not defined $db_version;

    die "This repository is up to date\n"
      if $db_version == $schema_version;

    die "This repository too new.  Upgrade Pinto instead\n"
      if $db_version > $schema_version;

    die "Migration is not implemented yet\n";
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------

1;

__END__
