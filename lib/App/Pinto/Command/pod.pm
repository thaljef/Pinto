package App::Pinto::Command::pod;

# ABSTRACT: show the packages in a stack

use strict;
use warnings;

use Pinto::Util qw(interpolate);

#-----------------------------------------------------------------------------

use base 'App::Pinto::Command';

#------------------------------------------------------------------------------

our $VERSION = '0.090'; # VERSION

#------------------------------------------------------------------------------

sub command_names { return qw( pod ) }

#------------------------------------------------------------------------------

sub opt_spec {
    my ( $self, $app ) = @_;

    return (
        [ 'author|A=s'        => 'Limit to distributions by author' ],
        [ 'distributions|D=s' => 'Limit to matching distribution names' ],
        [ 'pinned!'           => 'Limit to pinned packages (negatable)' ],
        [ 'stack|s=s'         => 'List contents of this stack' ],
        [ 'local-only'        => 'Limit to local packages' ],
        [ 'output=s'          => 'Directory for html output' ],
    );
}

#------------------------------------------------------------------------------

sub validate_args {
    my ( $self, $opts, $args ) = @_;

    $self->usage_error('Multiple arguments are not allowed')
        if @{$args} > 1;

    $opts->{stack} = $args->[0]
        if $args->[0];

    $self->usage_error('missing required options: output')
        unless $opts->{output};
    
    return 1;
}

#------------------------------------------------------------------------------

1;

