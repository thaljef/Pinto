# ABSTRACT: Remove one distribution from the repository

package Pinto::Action::Remove;

use Moose;

use Pinto::Util;
use Pinto::Exceptions qw(throw_error);

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

extends qw( Pinto::Action );

#------------------------------------------------------------------------------

with qw( Pinto::Role::Interface::Action::Remove );

#------------------------------------------------------------------------------


sub execute {
    my ($self) = @_;

    my $path    = $self->path();
    my $author  = $self->author();

    $path = ($path =~ m{/}mx) ? $path
                              : Pinto::Util::author_dir($author)->file($path)->as_foreign('Unix');

    my $dist = $self->repos->get_distribution(path => $path)
        || throw_error "Distribution $path does not exist";

    $self->repos->remove_distribution(dist => $dist);

    $self->add_message( Pinto::Util::removed_dist_message($dist) );

    return 1;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#------------------------------------------------------------------------------

1;

__END__
