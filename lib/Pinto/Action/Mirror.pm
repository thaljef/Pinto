package Pinto::Action::Mirror;

# ABSTRACT: An action to mirror a remote repository into your local one

use Moose;

use MooseX::Types::Moose qw(Bool);

use URI;
use Try::Tiny;

use Pinto::Util;

use namespace::autoclean;

extends 'Pinto::Action';

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------
# Moose Attributes

has force => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);

#------------------------------------------------------------------------------
# Moose Roles

with qw(Pinto::Role::UserAgent);

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    my $idxmgr  = $self->idxmgr();
    my $idx_changes = $idxmgr->update_mirror_index( force => $self->force() );
    return 0 if not $idx_changes and not $self->force();

    my $dist_changes = 0;
    for my $dist ( $idxmgr->dists_to_mirror() ) {
        try   { $dist_changes += $self->_do_mirror($dist) }
        catch { $self->logger->whine("Download of $dist failed: $_") };
    }

    return 0 if not ($idx_changes + $dist_changes);

    my $source = $self->config->source();
    $self->add_message("Mirrored $dist_changes distributions from $source");

    return 1;
}

#------------------------------------------------------------------------------

sub _do_mirror {
    my ($self, $dist) = @_;

    my $repos   = $self->config->repos();
    my $source  = $self->config->source();
    my $cleanup = !$self->config->nocleanup();

    my $url = $dist->url($source);
    my $destination = $dist->path($repos);
    return 0 if -e $destination;

    $self->fetch(url => $url, to => $destination) or return 0;
    $self->store->add(file => $destination);

    my @removed = $self->idxmgr->add_mirrored_distribution(dist => $dist);
    $cleanup && $self->store->remove(file => $_->path($repos)) for @removed;

    return 1;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#------------------------------------------------------------------------------

1;

__END__
