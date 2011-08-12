package Pinto::Action::Mirror;

# ABSTRACT: An action to mirror a remote repository into your local one

use Moose;

use URI;
use Try::Tiny;

use Pinto::Util;
use Pinto::UserAgent;

extends 'Pinto::Action';

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------
# Moose Roles

with qw(Pinto::Role::Downloadable);

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    my $idxmgr  = $self->idxmgr();
    my $changes = $idxmgr->update_mirror_index() or return 0;
    my @dists   = $idxmgr->dists_to_mirror();

    for my $dist ( @dists ) {
        try   { $changes += $self->_do_fetch($dist) }
        catch { $self->logger->whine("Download of $dist failed: $_") };
    }

    if ($changes) {
        my $count  = @dists;
        my $source = $self->config->source();
        $self->add_message("Mirrored $count distributions from $source");
    }

    # Don't include an index change, just because --force was on
    $changes -= $self->config->force();

    return $changes;
}

#------------------------------------------------------------------------------

sub _do_fetch {
    my ($self, $dist) = @_;

    my $local   = $self->config->local();
    my $source  = $self->config->source();
    my $cleanup = !$self->config->nocleanup();

    my $url = $dist->url($source);
    my $destination = $dist->path($local);
    return 0 if -e $destination;

    $self->fetch(url => $url, to => $destination) or return 0;
    $self->store->add(file => $destination);

    my @removed = $self->idxmgr->add_mirrored_distribution(dist => $dist);
    $cleanup && $self->store->remove(file => $_->path($local)) for @removed;

    return 1;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#------------------------------------------------------------------------------

1;

__END__
