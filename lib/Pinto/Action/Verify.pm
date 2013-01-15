# ABSTRACT: Report distributions that are missing

package Pinto::Action::Verify;

use Moose;

use Pinto::Util;

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

extends qw( Pinto::Action );

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    my $dist_rs = $self->repo->schema->select_distributions;

    while ( my $dist = $dist_rs->next ) {
        my $archive = $dist->archive( $self->repo->root_dir );
        $self->say("Missing distribution $archive") if not -e $archive;
    }

    return $self->result;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#------------------------------------------------------------------------------

1;

__END__
