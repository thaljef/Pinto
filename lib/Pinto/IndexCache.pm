package Pinto::IndexCache;

# ABSTRACT: Manages indexes files from remote repositories

use Moose;

use Package::Locator;

use Pinto::PackageSpec;
use Pinto::DistributionSpec;

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

    @args = ( $args[0]->name(), $args[0]->version() )
      if @args == 1 and ref $args[0] eq 'Pinto::PackageSpec';

    return $self->locator->locate(@args);
}

#-------------------------------------------------------------------------------

sub contents {
    my ($self) = @_;

    my %seen;
    for my $index ( $self->locator->indexes() ) {
        for my $dist ( values %{ $index->distributions() } ) {
            next if exists $seen{ $dist->{path} };

            # TODO: use coercion to do this for us
            my @pkg_specs = map { Pinto::PackageSpec->new( $_ ) }  @{ $dist->{packages} };
            $dist->{packages} = \@pkg_specs;

            my $dist_spec = Pinto::DistributionSpec->new( $dist );
            $seen{ $dist->{path} } = $dist_spec;
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
