package Pinto::Action::Verify;

# ABSTRACT: An action to verify all files are present in the repository

use Moose;
use Moose::Autobox;

use Pinto::Util;
use Pinto::Types 0.017 qw(IO);

extends 'Pinto::Action';

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

has out => (
    is       => 'ro',
    isa      => IO,
    coerce   => 1,
    default  => sub { [fileno(STDOUT), '>'] },
);

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    my $repos   = $self->config()->repos();
    my $dists   = $self->idxmgr->master_index->distributions->values();
    my $sorter  = sub {$_[0]->location() cmp $_[1]->location};

    for my $dist ( $dists->sort( $sorter )->flatten() ) {
        my $file = $dist->path($repos);
        print { $self->out } "Missing distribution $file\n" if not -e $file;
    }

    return 0;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#------------------------------------------------------------------------------

1;

__END__
