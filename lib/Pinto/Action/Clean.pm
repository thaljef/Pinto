# ABSTRACT: Remove orphaned archives

package Pinto::Action::Clean;

use Moose;

use Path::Class;
use File::Find;

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

extends qw( Pinto::Action );

#------------------------------------------------------------------------------

with qw( Pinto::Role::Reporter );

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    $self->repos->clean_files;

    return $self->result;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#-----------------------------------------------------------------------------
1;

__END__
