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
    handles    => [ qw(clear_cache) ],
    builder    => '_build_locator',
    lazy       => 1,
);

#-------------------------------------------------------------------------------
# Roles

with qw( Pinto::Role::Configurable
         Pinto::Role::Loggable );

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
            $dist->{packages} ||= []; # Prevent possible undef
            delete $_->{distribution} for @{ $dist->{packages} };
            $seen{ $dist->{path} } = $dist;
        }
    }

    return @seen{ sort keys %seen };

}

#-------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#-------------------------------------------------------------------------------

1;

__END__
