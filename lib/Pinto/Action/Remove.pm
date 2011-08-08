package Pinto::Action::Remove;

# ABSTRACT: An action to remove packages from the repository

use Moose;
use Moose::Autobox;
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

    my $pkg    = $self->package();
    my $author = $self->author();

    my $idxmgr = $self->idxmgr();
    my $orig_author = $idxmgr->local_author_of(package => $pkg);

    croak "You are $author, but only $orig_author can remove $pkg"
        if defined $orig_author and $author ne $orig_author;

    if (my $removed_dist = $idxmgr->remove_local_package(package => $pkg)) {

        # TODO: Dists should know their own path, or the store should
        # know how to resolve relative paths w/r/t some base dir.

        my $dist_location = $removed_dist->location();
        my $full_path = Path::Class::file($self->config->local(), qw(authors id), $dist_location );
        $self->store->remove(file => $full_path, prune => 1);


        my @removed_packages = $removed_dist->packages()->flatten();
        my @list_items = sort map { $_->name() . ' ' . $_->version() } @removed_packages;
        my $message = Pinto::Util::format_message("Removed archive $dist_location providing: ", @list_items);
        $self->_set_message($message);
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
