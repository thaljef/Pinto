package Pinto::Action::Mirror;

# ABSTRACT: An action to fill the repository from a mirror

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

has 'ua'      => (
    is         => 'ro',
    isa        => 'Pinto::UserAgent',
    default    => sub { Pinto::UserAgent->new() },
    init_arg   => undef,
);

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    my $idxmgr  = $self->idxmgr();
    my $changes = $idxmgr->update_mirror_index() or return 0;

    for my $dist ( $idxmgr->dists_to_mirror() ) {
        try { $changes += $self->_do_mirror($dist) }
      catch { $self->logger->whine("Mirror of $dist failed: $_") };
    }

    if ($changes) {
        my $msg = sprintf 'Updated to latest mirror of %s', $self->config->mirror();
        $self->add_message($msg);
    }
    return $changes;
}

#------------------------------------------------------------------------------

sub _do_mirror {
    my ($self, $dist) = @_;

    my $local   = $self->config->local();
    my $mirror  = $self->config->mirror();
    my $cleanup = !$self->config->nocleanup();

    my $url = $dist->url($mirror);
    my $destination = $dist->path($local);
    return 0 if -e $destination;

    $self->ua->mirror(url => $url, to => $destination) or return 0;
    $self->logger->info("Mirrored distribution $dist");
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
