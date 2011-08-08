package Pinto::Action::Remove;

# ABSTRACT: An action to remove packages from the repository

use Moose;
use MooseX::Types::Moose qw( Str );

use Carp;

extends 'Pinto::Action';

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

has package  => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

#------------------------------------------------------------------------------

with qw( Pinto::Role::Authored );

#------------------------------------------------------------------------------

override execute => sub {
    my ($self) = @_;

    $DB::single = 1;
    my $pkg    = $self->package();
    my $author = $self->author();

    my $idxmgr = $self->idxmgr();
    my $orig_author = $idxmgr->local_author_of(package => $pkg);

    croak "You are $author, but only $orig_author can remove $pkg"
        if defined $orig_author and $author ne $orig_author;

    if (my $removed_dist = $idxmgr->remove_local_package(package => $pkg)) {
        my $full_path = Path::Class::file($self->config->local(), qw(authors id), $removed_dist );
        $self->store->remove(file => $full_path, prune => 1);
        $self->_set_message("Removed $removed_dist");
        return 1;
    }

    $self->logger()->warn("Package $pkg is not in the index");
    return 0;
};

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#------------------------------------------------------------------------------

1;

__END__
