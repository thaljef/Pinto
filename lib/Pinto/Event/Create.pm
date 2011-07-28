package Pinto::Event::Create;

# ABSTRACT: An event to create a new repository

use Moose;

use Carp;
use Path::Class;

extends 'Pinto::Event';

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    # Someone could use the <create> event to pull an existing repository
    # out of VCS to a new location on the file system.  So if the
    # master index file already exists, then assume that the repository
    # has already been created and return false to indicate that
    # no commits are required.

    my $local = Path::Class::dir($self->config()->get_required('local'));
    return 0 if -e file($local, qw(modules 02packages.details.txt.gz));

    # Otherwise, let Pinto create the directories and index files
    # for us, and return true to indicate that a commit is required.

    $self->_set_message('Created a new Pinto repository');
    return 1;
}

#------------------------------------------------------------------------------

1;

__END__
