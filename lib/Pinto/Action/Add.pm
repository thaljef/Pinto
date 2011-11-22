package Pinto::Action::Add;

# ABSTRACT: Add one local distribution to the repository

use Moose;

use Path::Class;

use Pinto::Util;
use Pinto::Types 0.017 qw(File);
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

with qw( Pinto::Role::Authored
         Pinto::Role::Extractor );

#------------------------------------------------------------------------------
# Public methods

override execute => sub {
    my ($self) = @_;

    my $dist = $self->repos->add_archive( $self->archive(), $self->author() );
    $self->add_message( Pinto::Util::added_dist_message($dist) );

    return 1;
};

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#-----------------------------------------------------------------------------
1;

__END__
