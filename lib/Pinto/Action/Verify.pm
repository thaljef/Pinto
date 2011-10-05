package Pinto::Action::Verify;

# ABSTRACT: Verify all distributions are present in the repository

use Moose;

use Pinto::Util;
use Pinto::Types 0.017 qw(IO);

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
    my $rs    = $self->db->get_all_distributions();

    while ( my $dist = $rs->next() ) {
        my $file = $dist->native_path($repos);
        print { $self->out } "Missing distribution $file\n" if not -e $file;
    }

    return 0;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#------------------------------------------------------------------------------

1;

__END__
