package Pinto::Action::Rebuild;

# ABSTRACT: Rebuild the index file for the repository

use Moose;

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

extends 'Pinto::Action';

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    my $attrs   = {select => ['name'], distinct => 1};
    my $cursor  = $self->db->get_all_packages(undef, $attrs)->cursor();

    while (my ($name) = $cursor->next()) {
        $self->db->mark_latest_package_with_name( $name );
    }

    $self->add_message('Rebuilt the index');

    return 1;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#------------------------------------------------------------------------------

1;

__END__
