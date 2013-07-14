# ABSTRACT: Base class for interactive interfaces

package Pinto::Chrome;

use Moose;
use MooseX::StrictConstructor;
use MooseX::Types::Moose qw(Int Bool);
use MooseX::MarkAsMethods ( autoclean => 1 );

#-----------------------------------------------------------------------------

# VERSION

#-----------------------------------------------------------------------------

has verbose => (
    is      => 'ro',
    isa     => Int,
    default => 0,
);

has quiet => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);

#-----------------------------------------------------------------------------

sub show { return 1 }

#-----------------------------------------------------------------------------

sub diag { return 1 }

#-----------------------------------------------------------------------------

sub edit { return $_[1] }

#-----------------------------------------------------------------------------

sub show_progress { return 1 }

#-----------------------------------------------------------------------------

sub progress_done { return 1 }

#-----------------------------------------------------------------------------

sub should_render_diag {
    my ( $self, $level ) = @_;

    return 1 if $level == 0;                    # Always, always display errors
    return 0 if $self->quiet;                   # Don't display anything else if quiet
    return 1 if $self->verbose + 1 >= $level;
    return 0;
}

#-----------------------------------------------------------------------------

sub diag_levels { return qw(error warning notice info) }

#-----------------------------------------------------------------------------

my @levels = __PACKAGE__->diag_levels;
__generate_diag_method( $levels[$_], $_ ) for ( 0 .. $#levels );

#-----------------------------------------------------------------------------

sub __generate_diag_method {
    my ( $method_name, $diag_level ) = @_;

    my $template = <<'END_METHOD';
sub %s {
    my ($self, $msg, $opts) = @_;
    return unless $self->should_render_diag(%s);
    $self->diag($msg, $opts);
}
END_METHOD

    eval sprintf $template, $method_name, $diag_level;
    croak $@ if $@;
}

#-----------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#-----------------------------------------------------------------------------
1;

__END__


