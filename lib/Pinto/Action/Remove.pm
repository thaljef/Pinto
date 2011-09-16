package Pinto::Action::Remove;

# ABSTRACT: An action to remove one local distribution from the repository

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

has dist_name  => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

#------------------------------------------------------------------------------

with qw( Pinto::Role::Authored );

#------------------------------------------------------------------------------


override execute => sub {
    my ($self) = @_;

    my $dist_name  = $self->dist_name();
    my $author     = $self->author();
    my $cleanup    = !$self->config->nocleanup();

    # If the $dist_name looks like a precise location (i.e. it has
    # slashes), then use it as such.  But if not, then use the author
    # attribute to construct the precise location.
    my $location = $dist_name =~ m{/}mx ?
      $dist_name : Pinto::Util::author_dir($author)->file($dist_name)->as_foreign('Unix');

    # TODO: throw a more specialized exception.
    my $dist = $self->schema->get_distribution($location)
        or Pinto::Exception->throw("Distribution $location is not in the index");

    $self->logger->info(sprintf "Removing $dist with %i packages", $dist->package_count());
    $dist->delete();

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
