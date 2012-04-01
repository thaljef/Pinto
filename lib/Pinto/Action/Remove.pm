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

with qw( Pinto::Interface::Action::Remove );

#------------------------------------------------------------------------------


override execute => sub {
    my ($self) = @_;

    my $path    = $self->path();
    my $author  = $self->author();

    $path = $path =~ m{/}mx ? $path
                            : Pinto::Util::author_dir($author)->file($path)->as_foreign('Unix');

    my $where = {path => $path};
    my $dist  = $self->repos->select_distributions( $where )->single();
    throw_error "Distribution $path does not exist" if not $dist;

    # Must call accessor to ensure the package objects are attached
    # to the dist object before we delete.  Otherwise, we can't log
    # which packages were deleted, because they'll already be gone.
    my @pkgs = $dist->packages();
    my $count = @pkgs;

    $self->info("Removing distribution $dist with $count packages");

    $self->repos->remove_distribution($dist);

    $self->add_message( Pinto::Util::removed_dist_message($dist) );

    return 1;
};

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#------------------------------------------------------------------------------

1;

__END__
