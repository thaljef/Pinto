package Pinto::Event::Update;

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

    # TODO: Test that remote is available!

}

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    my $local  = $self->config()->get_required('local');
    my $remote = $self->config()->get_required('remote');

    my $remote_index_uri = URI->new("$remote/modules/02packages.details.txt.gz");
    $self->ua()->mirror(url => $remote_index_uri, to => $self->remote_index()->file());
    $self->remote_index()->reload();

    # TODO: Stop now if index has not changed, unless -force option is given.

    my $mirrorable_index = $self->remote_index() - $self->local_index();

    for my $file ( @{ $mirrorable_index->files() } ) {
        $self->log()->debug("Mirroring $file");
        my $remote_uri = URI->new( "$remote/authors/id/$file" );
        my $destination = Pinto::Util::native_file($local, 'authors', 'id', $file);
        my $changed = $self->mirror(url => $remote_uri, to => $destination);
        $self->log->info("Updated $file") if $changed;
    }

    my $message = "Updated to latest mirror of $remote";
    $self->_set_message($message);

    return 1;
}

#------------------------------------------------------------------------------

1;

__END__
