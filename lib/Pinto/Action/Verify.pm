# ABSTRACT: Report distributions that are missing

package Pinto::Action::Verify;

use Moose;
use MooseX::StrictConstructor;
use MooseX::MarkAsMethods ( autoclean => 1 );

use Pinto::Util qw(throw);

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

extends qw( Pinto::Action );

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    my $dist_rs = $self->repo->db->schema->distribution_rs;

    my $missing = 0;
    while ( my $dist = $dist_rs->next ) {

        if ( not -e $dist->native_path ) {
            $self->error("Missing distribution $dist");
            $missing++;
        }
    }

    throw("$missing archives are missing") if $missing;

    return $self->result;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------

1;

__END__
