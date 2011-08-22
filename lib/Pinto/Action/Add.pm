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
    required   => 1,
);

#------------------------------------------------------------------------------
# Roles

with qw( Pinto::Role::UserAgent );

#------------------------------------------------------------------------------

override execute => sub {
    my ($self) = @_;

    my $repos     = $self->config->repos();
    my $cleanup   = not $self->config->nocleanup();
    my $author    = $self->author();
    my $dist_file = $self->dist();

    # TODO: Consider moving Distribution construction to the index manager
    my $added   = Pinto::Distribution->new_from_file(file => $dist_file, author => $author);
    my @removed = $self->idxmgr->add_local_distribution(dist => $added, file => $dist_file);
    $self->logger->info(sprintf "Adding $added with %i packages", $added->package_count());

    $self->store->add( file => $added->path($repos), source => $dist_file );
    $cleanup && $self->store->remove( file => $_->path($repos) ) for @removed;

    $self->add_message( Pinto::Util::added_dist_message($added) );
    $self->add_message( Pinto::Util::removed_dist_message($_) ) for @removed;

    return 1;
};

#------------------------------------------------------------------------------

sub _is_url {
    my ($string) = @_;

    return $string =~ m/^ (?: http|ftp|file|) : /x;
}

#------------------------------------------------------------------------------

sub _dist_from_url {
    my ($self, $dist) = @_;

    my $url = URI->new($dist)->canonical();
    my $path = Path::Class::file( $url->path() );
    return $path if $url->scheme() eq 'file';

    my $base     = $path->basename();
    my $tempdir  = File::Temp::tempdir(CLEANUP => 1);
    my $tempfile = Path::Class::file($tempdir, $base);

    $self->fetch(url => $url, to => $tempfile);

    return Path::Class::file($tempfile);
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#-----------------------------------------------------------------------------
1;

__END__
