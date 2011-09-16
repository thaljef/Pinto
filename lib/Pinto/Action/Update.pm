package Pinto::Action::Update;

# ABSTRACT: An action to pull all the latest distributions into your repository

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
    my $idx_changes = $idxmgr->load_foreign_index();

    $DB::single = 1;
    my $foreigners = $idxmgr->foreign_distributions();
    return 0 if not $foreigners;

    my $dist_changes = 0;
    while (my $dist = $foreigners->next() ) {
        try   {
            $dist_changes += $self->_do_mirror($dist);
        }
        catch {
            $self->add_exception($_);
            $self->logger->whine("Download of $dist failed: $_");
        };
    }

    return 0 if not ($idx_changes + $dist_changes);

    my $source = $self->config->source();
    $self->add_message("Updated $dist_changes distributions from $source");

    return 1;
}

#------------------------------------------------------------------------------

sub _do_mirror {
    my ($self, $dist) = @_;

    my $repos   = $self->config->repos();
    my $source  = $self->config->source();

    my $url = $dist->url($source);
    my $destination = $dist->path($repos);
    return 0 if -e $destination;

    $self->fetch(url => $url, to => $destination) or return 0;
    $self->store->add(file => $destination);

    return 1;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#------------------------------------------------------------------------------

1;

__END__
