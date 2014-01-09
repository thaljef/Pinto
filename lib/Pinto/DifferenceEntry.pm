# ABSTRACT: Represents one addition or deletion in a diff

package Pinto::DifferenceEntry;

use Moose;
use MooseX::StrictConstructor;
use MooseX::MarkAsMethods ( autoclean => 1 );
use MooseX::Types::Moose qw(Str Bool);

use Pinto::Util qw(is_detailed_diff_mode);

#------------------------------------------------------------------------------

use overload (
    q{""} => 'to_string',
    'cmp' => 'string_compare',
);

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

# TODO: Consider breaking this into separate Addition and Deletion subclasses,
# rather than using an "op" attribute to indicate which kind it is.  That sort
# of "type" flag is always a code smell to me.

#------------------------------------------------------------------------------

has op => (
    is       => 'ro',
    isa      => Str,
    required => 1
);

has registration => (
    is       => 'ro',
    isa      => 'Pinto::Schema::Result::Registration',
    required => 1,
);

has detailed => (
    is       => 'ro',
    isa      => Bool,
    default  => \&is_detailed_diff_mode,
);

has format => (
    is      => 'ro',
    isa     => Str,
    default => sub { $_[0]->detailed ? "[%F] %-40p %12v %a/%f" : "[%F] %a/%f" },
    lazy    => 1,
);

#------------------------------------------------------------------------------

sub to_string {
    my ($self) = @_;

    return $self->op . $self->registration->to_string( $self->format );
}

#------------------------------------------------------------------------------

sub string_compare {
    my ( $self, $other ) = @_;

    return ( $self->registration->distribution->name cmp $other->registration->distribution->name );
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------
1;
