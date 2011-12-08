package Pinto::Store::File;

# ABSTRACT: Store a Pinto repository on the local filesystem

use Moose;

use Pinto::Exceptions qw(throw_fatal);

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
    $path->remove() or throw_fatal "Failed to remove path $path: $!";

    while (my $dir = $path->parent()) {
        last if $dir->children();
        $self->debug("Removing empty directory $dir");
        $dir->remove() or throw_fatal "Failed to remove directory $dir: $!";
        $path = $dir;
    }

    return $self;
};

#------------------------------------------------------------------------------
1;

__END__

=head1 DESCRIPTION

L<Pinto::Store::File> is the default back-end for a Pinto repository.
It basically just represents files on disk.  You should look at
L<Pinto::Store::VCS::Svn> or L<Pinto::Store::VCS::Git> for a more
interesting example.

=cut
