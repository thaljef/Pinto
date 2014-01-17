# ABSTRACT: Find a package/distribution target among CPAN-like repositories

package Pinto::Locator::Multiplex;

use Moose;
use MooseX::Types::Moose qw(ArrayRef);
use MooseX::MarkAsMethods (autoclean => 1);

use Pinto::Locator::Mirror;
use Pinto::Locator::Stratopan;
use Pinto::Constants qw(:stratopan);

#------------------------------------------------------------------------------

# VERSION

#-----------------------------------------------------------------------------

extends qw(Pinto::Locator);

#------------------------------------------------------------------------------

has locators => (
    is         => 'ro',
    isa        => ArrayRef['Pinto::Locator'],
    writer     => '_set_locators',
    default    => sub { [] },
    lazy       => 1,
);

#------------------------------------------------------------------------------

sub assemble {
    my ($self, @uris) = @_;

    my @locators;
    for my $uri (@uris) {
        my $class = $self->locator_class_for_uri($uri);
        # Ick: This assumes all Locators have same attributes
        my %args = ( uri => $uri, cache_dir => $self->cache_dir );
        push @locators, $class->new( %args );
    }

    $self->_set_locators(\@locators);
    return $self;
}

#------------------------------------------------------------------------------

sub locate_package {
    my ($self, %args) = @_;

    my @all_found;
    for my $locator ( @{ $self->locators } ) {
        next unless my $found = $locator->locate_package(%args);
        push @all_found, $found;
        last unless $args{cascade};
    }

    return if not @all_found;
    @all_found = reverse sort {$a->{version} <=> $b->{version}} @all_found;
    return $all_found[0];
}

#------------------------------------------------------------------------------

sub locate_distribution {
    my ($self, %args) = @_;

    for my $locator ( @{ $self->locators } ) {
        next unless my $found = $locator->locate_distribution(%args);
        return $found;
    }

    return;
}

#------------------------------------------------------------------------------

sub locator_class_for_uri {
    my ($self, $uri) = @_;

    my $baseclass = 'Pinto::Locator';
    my $subclass  = $uri eq $PINTO_STRATOPAN_CPAN_URI ? 'Stratopan' : 'Mirror';

    return $baseclass . '::' . $subclass;
}

#------------------------------------------------------------------------------


sub refresh {
    my ($self) = @_;

    $_->refresh for @{ $self->locators };

    return $self;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------

1;

__END__
