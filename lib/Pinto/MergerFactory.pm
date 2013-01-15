# ABSTRACT: Construct Merger objects

package Pinto::MergerFactory;

use Moose;
use MooseX::Types::Moose qw(HashRef);

use Class::Load;

use Pinto::Exception qw(throw);

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

has from_stack  => (
    is       => 'ro',
    isa      => 'Pinto::Schema::Result::Stack',
    required => 1,
);


has to_stack  => (
    is       => 'ro',
    isa      => 'Pinto::Schema::Result::Stack',
    required => 1,
);


has merge_options  => (
    is       => 'ro',
    isa      => HashRef,
    default  => sub { {} },
);

#------------------------------------------------------------------------------

with qw( Pinto::Role::Configurable
         Pinto::Role::Loggable );

#------------------------------------------------------------------------------

sub create_merger {
    my ($self) = @_;

    my $class;
    if ( $to_stack->head->is_ancestor_to($from_stack->head) ) {
        $class = 'Pinto::Merger::FastForward';
    }
    else {
        throw 'Recursive merge not implemented yet'
    }

    my %merger_args = ( config     => $self->config, 
                        logger     => $self->logger,
                        from_stack => $self->from_stack,
                        to_stack   => $self->to_stack,
                        %{ $self->merge_options } );

    Class::Load::load_class($class);
    return $class->new(%merger_args);
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------
1;

__END__
