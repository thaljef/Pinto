package Pinto::Action::Add;

# ABSTRACT: An action to add one distribution to the repository

use Moose;

use Pinto::Util;
use Pinto::Distribution;
use Pinto::Types qw(File AuthorID);

extends 'Pinto::Action';

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------
# Attrbutes

has dist => (
    is       => 'ro',
    isa      => File,
    required => 1,
    coerce   => 1,
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

    my $local     = $self->config->local();
    my $cleanup   = not $self->config->nocleanup();
    my $author    = $self->author();
    my $dist_file = $self->dist();

    # TODO: Consider moving Distribution construction to the index manager
    my $added   = Pinto::Distribution->new_from_file(file => $dist_file, author => $author);
    my @removed = $self->idxmgr->add_local_distribution(dist => $added, file => $dist_file);
    $self->logger->info(sprintf "Adding $added with %i packages", $added->package_count());

    $self->store->add( file => $added->path($local), source => $dist_file );
    $cleanup && $self->store->remove( file => $_->path($local) ) for @removed;

    $self->add_message( Pinto::Util::added_dist_message($added) );
    $self->add_message( Pinto::Util::removed_dist_message($_) ) for @removed;

    return 1;
};

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#-----------------------------------------------------------------------------
1;

__END__
