# ABSTRACT: Rebuild the index file for the repository

package Pinto::Action::Rebuild;

use Moose;

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

extends qw( Pinto::Action );

#------------------------------------------------------------------------------

with qw( Pinto::Role::Interface::Action::Rebuild );

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    $self->_recompute() if $self->recompute();

    return $self->result->changed; # To force rewrite of index
}

#------------------------------------------------------------------------------

sub _recompute {
    my ($self) = @_;

    # Gotta be a better way to to do this...
    my $attrs  = {select => ['name'], distinct => 1};
    my $cursor = $self->repos->select_packages(undef, $attrs)->cursor();

    while (my ($name) = $cursor->next()) {
        my $rs  = $self->repos->select_packages( {name => $name} );
        next if $rs->count() == 1;  # Only need to recompute if more than 1
        $self->debug("Recomputing latest version of package $name");
        $self->repos->db->mark_latest( $rs->first() );
    }

    return $self;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#------------------------------------------------------------------------------

1;

__END__
