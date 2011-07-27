package Pinto::Event::Remove;

# ABSTRACT: An event to remove one package from the repository

use Moose;

use Carp;

use Pinto::IndexManager;

extends 'Pinto::Event';

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

has author => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has package  => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

#------------------------------------------------------------------------------

sub prepare {
    my ($self) = @_;

    my $pkg    = $self->package();
    my $author = $self->author();

    my $idx_mgr = Pinto::IndexManager->instance();
    my $orig_author = $idx_mgr->local_author_of(package => $pkg);

    croak "Your are $author, but only $orig_author can remove $pkg"
      if defined $orig_author and $author ne $orig_author;

    return 1;
}

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    my $pkg = $self->package();
    my $idx_mgr = Pinto::IndexManager->instance();
    my @removed = $idx_mgr->remove_local_package(package => $pkg);
    my $message = "Removed local packages:\n\n" . join "\n", @removed;
    $self->_set_message($message);

    return 1;
}

#------------------------------------------------------------------------------

1;

__END__
