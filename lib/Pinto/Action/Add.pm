package Pinto::Action::Add;

# ABSTRACT: An action to add one local distribution to the repository

use Moose;

use Path::Class;
use File::Temp;

use Pinto::Util;
use Pinto::Types 0.017 qw(StrOrFileOrURI);

extends 'Pinto::Action';

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------
# Attrbutes

has dist_file => (
    is       => 'ro',
    isa      => StrOrFileOrURI,
    required => 1,
);

#------------------------------------------------------------------------------
# Roles

with qw( Pinto::Role::UserAgent
         Pinto::Role::Authored );

#------------------------------------------------------------------------------

override execute => sub {
    my ($self) = @_;

    my $repos     = $self->config->repos();
    my $cleanup   = not $self->config->nocleanup();
    my $author    = $self->author();
    my $dist_file = $self->dist_file();

    $dist_file = _is_url($dist_file) ? $self->_dist_from_url($dist_file) : file($dist_file);
    my ($added, @removed) = $self->idxmgr->add_local_distribution(file => $dist_file, author => $author);
    $self->logger->info(sprintf "Adding $added with %i packages", $added->package_count());

    $self->store->add( file => $added->path($repos), source => $dist_file );
    $cleanup && $self->store->remove( file => $_->path($repos) ) for @removed;

    $self->add_message( Pinto::Util::added_dist_message($added) );
    $self->add_message( Pinto::Util::removed_dist_message($_) ) for @removed;

    return 1;
};

#------------------------------------------------------------------------------

sub _is_url {
    my ($it) = @_;

    return 1 if eval { $it->isa('URI') };
    return 0 if eval { $it->isa('Path::Class::File') };
    return $it =~ m/^ (?: http|ftp|file|) : /x;
}

#------------------------------------------------------------------------------

sub _dist_from_url {
    my ($self, $dist_url) = @_;

    my $url = URI->new($dist_url)->canonical();
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
