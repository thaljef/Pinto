package Pinto::Config;

# ABSTRACT: User configuration for Pinto

use strict;
use warnings;

use Carp;
use Config::Tiny;
use Path::Class;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

sub new {
    my ($class, %args) = @_;
    my $profile = _find_profile(%args);

    croak "$profile does not exist" if defined $profile and not -e $profile;

    my $self = $profile ? Config::Tiny->read( file($profile) ) : {};
    return bless $self, $class;
}

#------------------------------------------------------------------------------

sub _find_profile {
    my %args = @_;
    return $args{profile} if defined $args{profile};
    return $ENV{PINTO} if defined $ENV{PINTO};
    return undef;
}

#-------------------------------------------------------------------------------

1;

__END__
