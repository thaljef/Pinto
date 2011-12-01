package Pinto::IndexCache;

# ABSTRACT: Manages indexes files from remote repositories

use Moose;

use Package::Locator;

use namespace::autoclean;

#-------------------------------------------------------------------------------

# VERSION

#-------------------------------------------------------------------------------
# Attributes

has locator => (
    is         => 'ro',
    isa        => 'Package::Locator',
    lazy_build => 1,
);

#-------------------------------------------------------------------------------
# Roles

with qw( Pinto::Interface::Configurable
         Pinto::Interface::Loggable );

#-------------------------------------------------------------------------------

sub _build_locator {
    my ($self) = @_;

    my @urls    = $self->config->sources_list();
    my $locator = Package::Locator->new( repository_urls => \@urls,
                                         cache_dir       => $self->config->cache_dir() );

    return $locator;
}

#-------------------------------------------------------------------------------

sub locate {
    my ($self, @args) = @_;

    return $self->locator->locate(@args);
}

#-------------------------------------------------------------------------------

sub contents {
    my ($self) = @_;

    my %seen;
    for my $index ( $self->locator->indexes() ) {
        for my $dist ( values %{ $index->distributions() } ) {
            next if exists $seen{ $dist->{path} };
            delete $_->{distribution} for @{ $dist->{packages} };
            $seen{ $dist->{path} } = $dist;
        }
    }

    # TODO: Return hash values sorted by the keys
    return values %seen;

}
#-------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#-------------------------------------------------------------------------------

1;

__END__
