package Pinto::Store::File;

# ABSTRACT: Store a Pinto repository on the local filesystem

use Moose;

use Carp;

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------
# ISA

extends qw( Pinto::Store );

#------------------------------------------------------------------------------
# Methods

augment remove_path => sub {
    my ($self, %args) = @_;

    my $path = $args{path};
    $path->remove() or confess "Failed to remove path $path: $!";

    while (my $dir = $path->parent()) {
        last if $dir->children();
        $self->debug("Removing empty directory $dir");
        $dir->remove() or confess "Failed to remove directory $dir: $!";
        $path = $dir;
    }

    return $self;
};

#------------------------------------------------------------------------------
1;

__END__
