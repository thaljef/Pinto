# ABSTRACT: Add a local distribution into the repository

package Pinto::Action::Add;

use Moose;
use MooseX::Attribute::Deflator;
use MooseX::Attribute::LazyInflator;
use MooseX::Types::Moose qw(Maybe Str);

use Pinto::Types qw(StackName);
use Pinto::Meta::Attribute::Trait::Inflatable;

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

extends qw( Pinto::Action );

#------------------------------------------------------------------------------

has pin   => (
    is      => 'ro',
    isa     => Maybe[Str],
    default => undef,
);

#------------------------------------------------------------------------------


with qw( Pinto::Role::Interface::Action::Add
         Pinto::Role::Attribute::stack );

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    $DB::single = 1;
    my $stack = $self->stack;

    my $dist  = $self->repos->add_distribution( archive   => $self->archive,
                                                author    => $self->author );

    $self->repos->register->( dist => $dist, stack => $stack );

    return $self->result->changed;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#-----------------------------------------------------------------------------
1;

__END__
