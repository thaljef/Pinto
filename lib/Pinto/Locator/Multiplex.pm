# ABSTRACT: Find a package/distribution target among CPAN-like repositories

package Pinto::Locator::Multiplex;

use Moose;
use MooseX::Types::Moose qw(ArrayRef);
use MooseX::MarkAsMethods (autoclean => 1);

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------

extends qw(Pinto::Locator);

#------------------------------------------------------------------------------

has locators => (
    is         => 'rw',
    isa        => ArrayRef['Pinto::Locator'],
    default    => sub { [] },
    lazy       => 1,
);

#------------------------------------------------------------------------------

sub assemble {
    my ($self, @urls) = @_;

    my @locators;
    for my $url (@urls) {
    
        my $locator;
        if ($url->host eq 'cpan.stratopan.com'){

            require Pinto::Locator::Stratopan;
            $locator = Pinto::Locator::Sratopan->new;

        }
        else {

            require Pinto::Locator::Mirror;
            my %args = ( url => $url, cache_dir => $self->cache_dir );
            $locator = Pinto::Locator::Mirror->new( %args );
        }

        push @locators, $locator;
    }

    $self->locators(\@locators);
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
