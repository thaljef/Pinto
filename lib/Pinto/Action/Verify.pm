package Pinto::Action::Verify;

# ABSTRACT: An action to verify all files are present in the repository

use Moose;
use Moose::Autobox;

use Pinto::Util;

extends 'Pinto::Action';

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    my $local = $self->config()->local();
    for my $location ( $self->idxmgr->master_index->files->keys->flatten() ) {
        my $file = Pinto::Util::native_file($local, 'authors', 'id', $location);
        print "Missing archive $file\n" if not -e $file;
    }

    return 0;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#------------------------------------------------------------------------------

1;

__END__
