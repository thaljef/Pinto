# ABSTRACT: Remove one distribution from the repository

package Pinto::Action::Remove;

use Moose;

use Carp;

use Pinto::Util;

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

extends qw( Pinto::Action );

#------------------------------------------------------------------------------

with qw( Pinto::Role::Interface::Action::Remove );

#------------------------------------------------------------------------------
# TODO: Change this to use the DistributionSpec

sub execute {
    my ($self) = @_;

    my $path    = $self->path;
    my $author  = $self->author;

    $path = ($path =~ m{/}mx) ? $path
                              : Pinto::Util::author_dir($author)->file($path)->as_foreign('Unix');

    my $dist = $self->repos->get_distribution(path => $path)
        or confess "Distribution $path does not exist";

    $self->repos->remove_distribution(dist => $dist);

    return $self->result->changed;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#------------------------------------------------------------------------------

1;

__END__
