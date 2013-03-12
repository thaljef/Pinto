# ABSTRACT: Migrate an existing repository to a new version

package Pinto::Migrator;

use Moose;
use MooseX::MarkAsMethods (autoclean => 1);

use Pinto;
use Pinto::Repository;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

with qw( Pinto::Role::Configurable );

#------------------------------------------------------------------------------


sub migrate {
    my ($self) = @_;

    my $pinto = Pinto->new(root => $self->config->root);

    my $repo_version = $pinto->repo->get_version;
    my $code_version = $Pinto::Repository::REPOSITORY_VERSION;

    die "This repository is too old to migrate.\n" .
        "Contact thaljef\@cpan.org for a migration plan.\n"
      if not $repo_version;

    die "This repository is already up to date.\n"
      if $repo_version == $code_version;

    die "This repository too new.  Upgrade Pinto instead.\n"
      if $repo_version > $code_version;

    die "Migration is not implemented yet\n";
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------

1;

__END__
