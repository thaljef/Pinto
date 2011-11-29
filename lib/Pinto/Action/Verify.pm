package Pinto::Action::Verify;

# ABSTRACT: Verify all distributions are present in the repository

use Moose;

use Pinto::Util;
use Pinto::Types qw(IO);

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------
# ISA

extends 'Pinto::Action';

#------------------------------------------------------------------------------
# Attributes

has out => (
    is       => 'ro',
    isa      => IO,
    coerce   => 1,
    default  => sub { [fileno(STDOUT), '>'] },
);

#------------------------------------------------------------------------------
# Methods

sub execute {
    my ($self) = @_;

    my $repos = $self->config()->repos();
    my $rs    = $self->db->select_distributions();

    while ( my $dist = $rs->next() ) {
        my $archive = $dist->archive($repos);
        print { $self->out } "Missing distribution $archive\n" if not -e $archive;
    }

    return 0;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#------------------------------------------------------------------------------

1;

__END__
