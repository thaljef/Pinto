# ABSTRACT: Show or change stack properties

package Pinto::Action::Props;

use Moose;
use MooseX::StrictConstructor;
use MooseX::MarkAsMethods ( autoclean => 1 );
use MooseX::Types::Moose qw(Str HashRef);

use String::Format qw(stringf);

use Pinto::Constants qw(:color);
use Pinto::Util qw(is_system_prop);
use Pinto::Types qw(StackName StackDefault StackObject);

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

extends qw( Pinto::Action );

#------------------------------------------------------------------------------

with qw( Pinto::Role::Transactional );

#------------------------------------------------------------------------------

has stack => (
    is  => 'ro',
    isa => StackName | StackDefault | StackObject,
);

has properties => (
    is        => 'ro',
    isa       => HashRef,
    predicate => 'has_properties',
);

has format => (
    is      => 'ro',
    isa     => Str,
    default => "%p = %v",
);

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    my $stack = $self->repo->get_stack( $self->stack );

    $self->has_properties
        ? $self->_set_properties($stack)
        : $self->_show_properties($stack);

    return $self->result;
}

#------------------------------------------------------------------------------

sub _set_properties {
    my ( $self, $target ) = @_;

    $target->set_properties( $self->properties );

    $self->result->changed;

    return;
}

#------------------------------------------------------------------------------

sub _show_properties {
    my ( $self, $target ) = @_;

    my $props = $target->get_properties;
    while ( my ( $prop, $value ) = each %{$props} ) {

        my $string = stringf( $self->format, { p => $prop, v => $value } );
        my $color = is_system_prop($prop) ? $PINTO_PALETTE_COLOR_2 : undef;

        $self->show( $string, { color => $color } );
    }

    return;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------

1;

__END__
