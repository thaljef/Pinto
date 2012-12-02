# ABSTRACT: Show or change configuration

package Pinto::Action::Config;

use Moose;
use MooseX::Types::Moose qw(Str HashRef);


use String::Format qw(stringf);

use Pinto::Types qw(StackName StackObject);

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

extends qw( Pinto::Action );

#------------------------------------------------------------------------------

with qw( Pinto::Role::Transactional );

#------------------------------------------------------------------------------

has stack => (
    is        => 'ro',
    isa       => StackName | StackObject,
    predicate => 'has_stack',
);


has properties => (
    is        => 'ro',
    isa       => HashRef,
    predicate => 'has_properties',
);


has format => (
    is      => 'ro',
    isa     => Str,
    default => "%n = %v",
);

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    my $target = $self->has_stack ? $self->repo->get_stack($self->stack)
                                  : $self->repo;

    $self->has_properties ? $self->_set_properties($target)
                          : $self->_show_properties($target);

    return $self->result;
}

#------------------------------------------------------------------------------

sub _set_properties {
    my ($self, $target) = @_;

    $target->set_properties($self->properties);
    $self->result->changed;

    return;
}

#------------------------------------------------------------------------------

sub _show_properties {
    my ($self, $target) = @_;

    my $props = $target->get_properties;
    while ( my ($prop, $value) = each %{$props} ) {
        $self->say(stringf($self->format, {n => $prop, v => $value}));
    }

    return;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------

1;

__END__
