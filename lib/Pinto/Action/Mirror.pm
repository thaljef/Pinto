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

    my $local  = $self->config->local();
    my $mirror = $self->config->mirror();
    my $force  = $self->config->force();

    my $idxmgr = $self->idxmgr();
    my $index_has_changed = $idxmgr->update_mirror_index();

    if (not $index_has_changed and not $force) {
        $self->logger->log("Mirror index has not changed");
        return 0;
    }

    for my $file ( $idxmgr->files_to_mirror() ) {

        my $mirror_uri = URI->new( "$mirror/authors/id/$file" );
        my $destination = Pinto::Util::native_file($local, 'authors', 'id', $file);
        next if -e $destination;

        my $file_has_changed = $self->ua->mirror(url => $mirror_uri, to => $destination, croak => 0);
        $self->logger->log("Mirrored archive $file") if $file_has_changed;
    }

    my $message = "Updated to latest mirror of $mirror";
    $self->_set_message($message);

    return 1;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#------------------------------------------------------------------------------

1;

__END__
