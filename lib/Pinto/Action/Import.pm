# ABSTRACT: Import an upstream distribution into the repository

package Pinto::Action::Import;

use Moose;

use Pinto::Types qw(StackName);

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

extends qw( Pinto::Action );

#------------------------------------------------------------------------------

has stack => (
    is      => 'ro',
    isa     => StackName,
    default => 'default',
);

#------------------------------------------------------------------------------

with qw( Pinto::Role::PackageImporter
         Pinto::Role::Interface::Action::Import );

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    my ($dist, $did_import) = $self->find_or_import( $self->target );
    return $self->result if not $dist;


    unless ( $self->norecurse ) {
        my $archive = $dist->archive( $self->repos->root_dir );
        my @imported_prereqs = $self->import_prerequisites( $archive, $self->stack );
        $did_import += @imported_prereqs;
    }

    $self->result->changed if $did_import;

    return $self->result;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#------------------------------------------------------------------------------

1;

__END__
