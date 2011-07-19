package Pinto::Config;

use strict;
use warnings;

use Carp;
use Config::Tiny;
use Path::Class;

sub new {
    my ($class, %args) = @_;
    my $config_file = _config_file(%args);
    my $self = Config::Tiny->read($config_file);
    return bless $self, $class;
}

#----------------------------------------------------------------------------------------------

sub _config_file {

    my %options = @_;
    my $config_file = do {
        if (defined $options{config_file} ) {
            $options{config_file};
        } elsif (defined $ENV{PINTO}) {
            $ENV{PINTO};
        }
    };

    return if not defined $config_file;
    croak "$config_file does not exist" if not -e $config_file;
    return file($config_file);
}

1;

