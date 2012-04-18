# ABSTRACT: An action to create a new stack by copying another

package Pinto::Action::Stack::Copy;

use Moose;

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

extends 'Pinto::Action';

#------------------------------------------------------------------------------

with qw( Pinto::Role::Interface::Action::Stack::Copy );

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    my $from_stack = $self->_check_stacks();
    my $to_stack   = $self->_copy_stack($from_stack);
    $self->_copy_stack_members($from_stack, $to_stack);

    return $self->result->changed;
}

#------------------------------------------------------------------------------

sub _check_stacks {
    my ($self) = @_;

    my $from_stack_name = $self->from_stack;
    my $from_stack = $self->repos->get_stack( name => $from_stack_name )
        or $self->fatal("Source stack $from_stack_name does not exist");

    my $to_stack_name = $self->to_stack;
    $self->repos->get_stack( name => $to_stack_name )
        and $self->fatal("Target stack $to_stack_name already exists");

    return $from_stack;
}

#------------------------------------------------------------------------------

sub _copy_stack {
    my ($self, $from_stack) = @_;

    $self->notice( sprintf 'Creating new stack %s', $self->to_stack() );

    my $changes = { name => $self->to_stack };
    $changes->{description} = $self->description if $self->has_description();
    my $to_stack = $from_stack->copy( $changes );

    return $to_stack;
}

#------------------------------------------------------------------------------

sub _copy_stack_members {
    my ($self, $from_stack, $to_stack) = @_;

    $self->notice("Copying stack $from_stack into stack $to_stack");

    for my $packages_stack ( $from_stack->packages_stack ) {
        my $pkg = $packages_stack->package;
        $self->debug("Copying package $pkg into stack $to_stack");
        $packages_stack->copy( { stack => $to_stack->id } );
    }

    # TODO: Make sure both stacks have the same mtime after copying

    return;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#------------------------------------------------------------------------------

1;

__END__
