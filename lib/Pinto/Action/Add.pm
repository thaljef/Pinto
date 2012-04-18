# ABSTRACT: Add a local distribution into the repository

package Pinto::Action::Add;

use Moose;
use MooseX::Types::Moose qw(Maybe Str);

use Pinto::Types qw(StackName);

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


has stack => (
    is      => 'ro',
    isa     => StackName,
    default => 'default',
);

#------------------------------------------------------------------------------

with qw( Pinto::Role::FileFetcher
         Pinto::Role::PackageImporter
         Pinto::Role::Interface::Action::Add );

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    my $dist = $self->repos->add_distribution( archive   => $self->archive,
                                               author    => $self->author,
                                               stack     => $self->stack,
                                               pin       => $self->pin );

    unless ( $self->norecurse ) {
        my $archive = $dist->archive( $self->repos->root_dir );
        $self->import_prerequisites( $archive, $self->stack );
    }

    return $self->result->changed;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#-----------------------------------------------------------------------------
1;

__END__
