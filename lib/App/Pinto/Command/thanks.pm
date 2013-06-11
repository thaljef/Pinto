package App::Pinto::Command::thanks;

# ABSTRACT: show my gratitude

use strict;
use warnings;

use Path::Class qw(dir);
use Pod::Usage qw(pod2usage);

use base qw(App::Pinto::Command);

#-------------------------------------------------------------------------------

# VERSION

#-------------------------------------------------------------------------------

sub execute {
    my ($self, $opts, $args) = @_;

    my $path;
    for my $dir (@INC) {
        my $maybe = dir($dir)->file( qw(Pinto Manual Thanks.pod) );
        do { $path = $maybe->stringify; last } if -f $maybe;
    }

    die "Could not find the Thanks pod.\n" if not $path;

    pod2usage(
        -verbose  => 99,
        -sections => 'THANK YOU',
        -input    => $path,
        -exitval  => 0,
    );

    return 1;
}

#-------------------------------------------------------------------------------
1;

