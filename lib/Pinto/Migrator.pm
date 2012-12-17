# ABSTRACT: Migrate an existing Pinto repository to a new version

package Pinto::Migrator;

use Moose;

use Pinto::Exception qw(throw);

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

with qw( Pinto::Role::Configurable
	     Pinto::Role::Loggable );

#------------------------------------------------------------------------------


sub migrate {
    my ($self) = @_;

    throw 'Migration is not implemented yet';
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------

1;

__END__
