package Pinto::Action::Remove;

# ABSTRACT: An action to remove packages from the repository

use Moose;
use MooseX::Types::Moose qw( Str );

use Pinto::Util;
use Pinto::Exception;

extends 'Pinto::Action';

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------
# Attributes

has package  => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

#------------------------------------------------------------------------------

with qw( Pinto::Role::Authored );

#------------------------------------------------------------------------------


override execute => sub {
    my ($self) = @_;

    my $pkg     = $self->package();
    my $author  = $self->author();
    my $idxmgr  = $self->idxmgr();
    my $cleanup = not $self->config->nocleanup();

    my $dist = $idxmgr->remove_local_package(package => $pkg, author => $author)
        or Pinto::Exception->throw("Package $pkg is not in the local index");

    $self->logger->info(sprintf "Removing $dist with %i packages", $dist->package_count());

    my $file = $dist->path( $self->config->repos() );
    $self->store->remove( file => $file ) if $cleanup;

    $self->add_message( Pinto::Util::removed_dist_message( $dist ) );

    return 1;
};

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#------------------------------------------------------------------------------

1;

__END__
