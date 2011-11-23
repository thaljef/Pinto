package Pinto::IndexCache;

# ABSTRACT: Manages indexes files from remote repositories

use Moose;

use Package::Locator;

use namespace::autoclean;

#-------------------------------------------------------------------------------

# VERSION

#-------------------------------------------------------------------------------
# Attributes

has _locator => (
    is         => 'ro',
    isa        => 'Package::Locator',
    lazy_build => 1,
);

#-------------------------------------------------------------------------------
# Roles

with qw( Pinto::Role::Configurable
         Pinto::Role::Loggable );

#-------------------------------------------------------------------------------

sub _build__locator {
    my ($self) = @_;

    $DB::single = 1;
    my @urls    = $self->config->sources_list();
    my $locator = Package::Locator->new( repository_urls => \@urls,
                                         cache_dir       => $self->config->cache_dir() );

    return $locator;
}

#-------------------------------------------------------------------------------

sub locate {
    my ($self, @args) = @_;

    return $self->_locator->locate(@args);
}

#-------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#-------------------------------------------------------------------------------

1;

__END__
