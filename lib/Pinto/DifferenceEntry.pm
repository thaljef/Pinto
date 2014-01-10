# ABSTRACT: Represents one addition or deletion in a diff

package Pinto::DifferenceEntry;

use Moose;
use MooseX::StrictConstructor;
use MooseX::MarkAsMethods ( autoclean => 1 );
use MooseX::Types::Moose qw(Str);

use String::Format;

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

#------------------------------------------------------------------------------

sub is_addition { shift->op eq '+' }

sub is_deletion { shift->op eq '-' }

#------------------------------------------------------------------------------

sub to_string {
    my ( $self, $format ) = @_;

    my %fspec = ( o => $self->op );

    $format ||= $self->default_format;
    return $self->registration->to_string( String::Format::stringf($format, %fspec) );
}

#------------------------------------------------------------------------------

sub default_format {
    my ($self) = @_;

    return '%o[%F] %-40p %12v %a/%f',
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
