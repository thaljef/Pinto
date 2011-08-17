package Pinto::Action::List;

# ABSTRACT: An action that lists the contents of a repository

use Moose;
use Pinto::Types qw(IO);

extends 'Pinto::Action';

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------
# TODO: default this to STDOUT.  Not sure how to to do this with an IO type.

has out => (
    is      => 'ro',
    isa     => IO,
);

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    # TODO: force log_level to quiet when running this action.

    for my $package ( $self->idxmgr()->all_packages() ) {
        my $fh = $self->out() || \*STDOUT;
        print { $fh } $package->to_index_string();
    }

    return 0;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#------------------------------------------------------------------------------

1;

__END__
