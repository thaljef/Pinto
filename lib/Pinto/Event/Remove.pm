package Pinto::Event::Remove;

# ABSTRACT: An event to remove packages from the repository

use Moose;

use Carp;

use Pinto::IndexManager;

extends 'Pinto::Event';

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

has package  => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

#------------------------------------------------------------------------------

sub prepare {
    my ($self) = @_;

    my $pkg    = $self->package();
    my $author = $self->config()->get_required('author');

    my $idx_mgr = Pinto::IndexManager->instance();
    my $orig_author = $idx_mgr->local_author_of(package => $pkg);

    croak "You are $author, but only $orig_author can remove $pkg"
      if defined $orig_author and $author ne $orig_author;

    return 1;
}

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    my $pkg = $self->package();
    my $idx_mgr = Pinto::IndexManager->instance();
    my @removed = $idx_mgr->remove_local_package(package => $pkg);

    if (@removed) {
        my $message = "Removed packages:\n    " . join "\n    ", @removed;
        $self->_set_message($message);
        return 1;
    }
    else {
        $self->log()->warn("Package $pkg is not in the local index");
        return 0;
    }
}

#------------------------------------------------------------------------------

1;

__END__
