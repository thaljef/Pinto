package Pinto::Action::Remove;

# ABSTRACT: An action to remove packages from the repository

use Moose;
use MooseX::Types::Moose qw( Str );

use Pinto::Util;
use Pinto::Types qw(AuthorID);

extends 'Pinto::Action';

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

has package  => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);


has author => (
    is         => 'ro',
    isa        => AuthorID,
    coerce     => 1,
    lazy_build => 1,
);

#------------------------------------------------------------------------------

sub _build_author { return shift()->config->author() }

#------------------------------------------------------------------------------

override execute => sub {
    my ($self) = @_;

    my $pkg    = $self->package();
    my $author = $self->author();
    my $idxmgr = $self->idxmgr();

    my $dist = $idxmgr->remove_local_package(package => $pkg, author => $author);
    $self->logger->warn("Package $pkg is not in the local index") && return 0 if not $dist;
    $self->logger->log(sprintf "Removing $dist with %i packages", $dist->package_count());

    my $file = $dist->path( $self->config->local() );
    $self->store->remove( file => $file, prune => 1 );

    $self->add_message( Pinto::Util::removed_dist_message( $dist ) );

    return 1;
};

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#------------------------------------------------------------------------------

1;

__END__
