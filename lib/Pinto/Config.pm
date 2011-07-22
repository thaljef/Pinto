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
    my $self = $profile ? Config::Tiny->read($profile) : {};
    return bless $self, $class;
}

#------------------------------------------------------------------------------

sub _find_profile {
    my %args = @_;

    $DB::single = 1;
    my $profile = do {
        if (defined $args{profile} ) {
            $args{profile};
        } elsif (defined $ENV{PINTO}) {
            $ENV{PINTO};
        }
    };

    return if not defined $profile;
    croak "$profile does not exist" if not -e $profile;
    return file($profile);
}

#-------------------------------------------------------------------------------

1;

__END__
