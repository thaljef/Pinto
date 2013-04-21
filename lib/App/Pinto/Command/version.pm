package App::Pinto::Command::version;

# ABSTRACT: show version information

use strict;
use warnings;

use Class::Load qw();

use base qw(App::Pinto::Command);

#-------------------------------------------------------------------------------

# VERSION

#-------------------------------------------------------------------------------

sub execute {
    my ($self, $opts, $args) = @_;

    my $app_class = ref $self->app();
    my $app_version = $self->app->VERSION || '?';
    print "$app_class $app_version\n";

    for my $pinto_class ( qw(Pinto Pinto::Remote) ) {
        Class::Load::try_load_class( $pinto_class ) or next;
        my $pinto_version = $pinto_class->VERSION || '?';
        print "$pinto_class $pinto_version\n";
    }

    return 0;
}

#-------------------------------------------------------------------------------

=head1 DESCRIPTION

This command simply displays some version information about this application.

=cut

1;

