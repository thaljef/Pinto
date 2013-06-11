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

    my ($cmd, undef, undef) = $self->app->prepare_command(@$args);

    my $path;
    for my $dir (@INC) {
        $path = dir($dir)->file( qw( Pinto Manual Thanks.pod) );
        last if -e $path;
    }

    die "Could not find the Thanks pod.\n" if not $path;

    pod2usage(-verbose => 2, -input => "$path", -exitval => 0);

    return 1;
}

#-------------------------------------------------------------------------------
1;

