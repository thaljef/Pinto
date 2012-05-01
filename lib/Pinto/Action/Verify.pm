# ABSTRACT: Verify all distributions are present in the repository

package Pinto::Action::Verify;

use Moose;

use Pinto::Util;

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

extends qw( Pinto::Action );

#------------------------------------------------------------------------------

with qw( Pinto::Role::Interface::Action::Verify );

#------------------------------------------------------------------------------
# Methods

sub execute {
    my ($self) = @_;


    # FIXME!
    my $rs  = $self->repos->db->schema->resultset('Distribution')->search;

    while ( my $dist = $rs->next ) {
        my $archive = $dist->archive( $self->repos->root_dir );
        print { $self->out } "Missing distribution $archive\n" if not -e $archive;
    }

    return $self->result;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#------------------------------------------------------------------------------

1;

__END__
