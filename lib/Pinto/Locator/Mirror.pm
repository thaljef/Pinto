# ABSTRACT: The package index of a repository

package Pinto::Locator::Mirror;

use Moose;
use MooseX::StrictConstructor;
use MooseX::Types::Moose qw(HashRef);
use MooseX::MarkAsMethods (autoclean => 1);

use URI;
use URI::Escape;

use Pinto::Types qw(Uri File);
use Pinto::Util qw(throw);
use Pinto::IndexReader;

use version;

#------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------

extends qw(Pinto::Locator);

#------------------------------------------------------------------------

with qw(Pinto::Role::UserAgent);

#------------------------------------------------------------------------

has index_file => (
    is         => 'ro',
    isa        => File,
    builder    => '_build_index_file',
    clearer    => '_clear_index_file',
    lazy       => 1,
);

has reader => (
    is        => 'ro',
    isa       => 'Pinto::IndexReader',
    default   => sub { Pinto::IndexReader->new(index_file => $_[0]->index_file)},
    clearer   => '_clear_reader',
    lazy      => 1,
);

#------------------------------------------------------------------------------

sub _build_index_file {
    my ($self) = @_;

    my $uri = $self->uri->canonical->as_string;
    $uri =~ s{ /*$ }{}mx;   # Remove trailing slash
    $uri = URI->new($uri);  # Reconstitute as URI object (why?)

    my $details_filename = '02packages.details.txt.gz';
    my $cache_dir = $self->cache_dir->subdir( URI::Escape::uri_escape($uri) );
    my $destination = $cache_dir->file($details_filename);
    my $source = URI->new( "$uri/modules/$details_filename" );

    $self->mirror($source => $destination);

    return $destination;
}

#------------------------------------------------------------------------

sub locate_package {
    my ($self, %args) = @_;

    my $target = $args{target};
 
    return unless my $found = $self->reader->packages->{$target->name};
    return unless $target->is_satisfied_by( $found->{version} );

    # Morph data structure to meet spec
    $found = { %$found }; # Cloning
    $found->{package} = delete $found->{name};
    $found->{uri} = URI->new($self->uri . "/authors/id/$found->{path}");
    $found->{version} = version->parse($found->{version});
    delete $found->{path};

    return $found;
}

#------------------------------------------------------------------------

sub locate_distribution {
    my ($self, %args) = @_;

    my $target = $args{target};
    my $path  = $target->path;
    
    my @extensions = qw(tar.gz tar.bz2 tar gz tgz bz2 zip z);
    my $has_extension = $path =~ m/[.](?:tar|gz|tgz|zip|z|bz2)$/i;
    my @paths_to_try = $has_extension ? ($path) : map { "$path.$_" } @extensions;

    for my $path (@paths_to_try) {
        my $uri  = URI->new($self->uri . '/authors/id/' . $path);
        return {uri => $uri} if $self->head($uri)->is_success;
    }

    return;
}

#------------------------------------------------------------------------

sub refresh {
    my ($self) = @_;

    $self->index_file->remove;
    $self->_clear_index_file;
    $self->_clear_reader;

    return $self;
}
#------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------
1;

__END__
