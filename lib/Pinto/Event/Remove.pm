package Pinto::Event::Remove;

# ABSTRACT: An event to remove one package from the repository

use Moose;

use Carp;

extends 'Pinto::Event';

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

has author => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has package_name => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

#------------------------------------------------------------------------------

sub prepare {
    my ($self) = @_;

    my $package_name = $self->package_name();
    my $author = $self->config()->get_required('author');

    my $incumbent_package = $self->local_index()->packages_by_name->{$package_name};

    if ($incumbent_package) {
        my $incumbent_author = $incumbent_package->author();
        croak "Only author $incumbent_author can remove package $package_name.\n"
            if $incumbent_author ne $author;
    }
    else {
        $self->log()->info("$package_name is not in the local index");
    }

    return 1;
}

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    my $local  = $self->config()->get_required('local');
    my $package_name = $self->package_name();

    my @local_removed = $self->local_index()->remove($package_name);
    $self->log->info("Removed $_ from local index") for @local_removed;
    $self->local_index()->write();

    my @master_removed = $self->master_index()->remove($package_name);
    $self->log->info("Removed $_ from master index") for @master_removed;
    $self->master_index()->write();

    my $message = "Removed local packages:\n\n" . join '\n', @local_removed;
    $self->_set_message($message);

    return 1;
}

#------------------------------------------------------------------------------

1;

__END__
