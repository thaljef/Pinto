package Pinto::Action::Add;

# ABSTRACT: Add one local distribution to the repository

use Moose;

use Path::Class;

use Pinto::Util;
use Pinto::Types qw(File);
use Pinto::Exceptions qw(throw_error);

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------
# ISA

extends 'Pinto::Action';

#------------------------------------------------------------------------------
# Attrbutes

has archive => (
    is       => 'ro',
    isa      => File,
    required => 1,
    coerce   => 1,
);

#------------------------------------------------------------------------------
# Roles

with qw( Pinto::Interface::Authorable );

#------------------------------------------------------------------------------
# Public methods

override execute => sub {
    my ($self) = @_;

    my $dist = $self->repos->add_distribution( archive => $self->archive(),
                                               author  => $self->author() );

    $self->add_message( Pinto::Util::added_dist_message($dist) );

    return 1;
};

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#-----------------------------------------------------------------------------
1;

__END__
