package Pinto::Config;

use strict;
use warnings;

use Config::Tiny;

sub new {
    my ($class, @args) = @_;
    my $self = Config::Tiny->read("$ENV{HOME}/.padrc");
    return bless $self, $class;
}

1;

