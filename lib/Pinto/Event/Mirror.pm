package Pinto::Event::Mirror;

# ABSTRACT: An event to fill the repository from a mirror

use Moose;

use Pinto::Util;
use URI;

extends 'Pinto::Event';

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

has 'ua'      => (
    is         => 'ro',
    isa        => 'Pinto::UserAgent',
    default    => sub { Pinto::UserAgent->new() },
    handles    => [qw(mirror)],
    init_arg   => undef,
);

#------------------------------------------------------------------------------

sub prepare {
    my ($self) = @_;

    # TODO: Test that mirror is available!

}

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    my $local  = $self->config()->get_required('local');
    my $mirror = $self->config()->get_required('mirror');

    my $mirror_index_uri = URI->new("$mirror/modules/02packages.details.txt.gz");
    $self->ua()->mirror(url => $mirror_index_uri, to => $self->mirror_index()->file());
    $self->mirror_index()->reload();

    # TODO: Stop now if index has not changed, unless -force option is given.

    my $mirrorable_index = $self->mirror_index() - $self->local_index();

    for my $file ( @{ $mirrorable_index->files() } ) {
        $self->log()->debug("Mirroring $file");
        my $mirror_uri = URI->new( "$mirror/authors/id/$file" );
        my $destination = Pinto::Util::native_file($local, 'authors', 'id', $file);
        my $changed = $self->mirror(url => $mirror_uri, to => $destination);
        $self->log->info("Mirrored $file") if $changed;
    }

    my $message = "Updated to latest mirror of $mirror";
    $self->_set_message($message);

    return 1;
}

#------------------------------------------------------------------------------

1;

__END__
