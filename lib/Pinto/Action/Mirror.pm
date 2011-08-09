package Pinto::Action::Mirror;

# ABSTRACT: An action to fill the repository from a mirror

use Moose;

use URI;

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
    $changes   += $self->_do_mirror($_) for $idxmgr->dists_to_mirror();

    my $message = sprintf 'Updated to latest mirror of %s', $self->mirror();
    $self->_set_message($message);

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
    next if -e $destination;

    my $changes_were_made = 0;
    if ( $self->ua->mirror(url => $url, to => $destination, croak => 0) ) {
        $self->logger->log("Mirrored distribution $dist");
        $self->store->add(file => $destination);
        my @removed = $self->idxmgr->add_mirrored_distribution(dist => $dist);
        $cleanup && $self->store->remove(file => $_->path($local)) for @removed;
        $changes_were_made++;
    }

    return $changes_were_made;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#------------------------------------------------------------------------------

1;

__END__
