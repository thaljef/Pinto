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

has file => (
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

    my $local   = $self->config->local();
    my $cleanup = !$self->config->nocleanup();
    my $author  = $self->author();
    my $file    = $self->file();


    my $added   = Pinto::Distribution->new_from_file( file   => $file, author => $author );
    my @removed = $self->idxmgr->add_local_distribution( dist => $added );
    $self->logger->log(sprintf "Adding $added with %i packages", $added->package_count());

    $self->store->add( file => $added->path($local), source => $file );
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
