# ABSTRACT: Report distributions that are missing

package Pinto::Action::Verify;

use Moose;
use MooseX::MarkAsMethods (autoclean => 1);

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

extends qw( Pinto::Action );

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    my $dist_rs = $self->repo->db->schema->distribution_rs;

    while ( my $dist = $dist_rs->next ) {
        my $archive = $dist->native_path( $self->repo->config->authors_id_dir );
        $self->say("Missing distribution $dist") if not -e $archive;
    }

    return $self->result;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------

1;

__END__
