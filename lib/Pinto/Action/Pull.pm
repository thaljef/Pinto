# ABSTRACT: Pull an upstream distribution into the repository

package Pinto::Action::Pull;

use Moose;

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

extends qw( Pinto::Action );

#------------------------------------------------------------------------------

with qw( Pinto::Role::Interface::Action::Pull
         Pinto::Role::PackageImporter );

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    my ($dist, $did_import) = $self->find_or_import( $self->target );
    return $self->result if not $dist;

    $self->repos->register( distribution  => $dist,
                            stack         => $self->stack );

    unless ( $self->norecurse ) {
        my $archive = $dist->archive( $self->repos->root_dir );
        my @imported_prereqs = $self->import_prerequisites( $archive );
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
