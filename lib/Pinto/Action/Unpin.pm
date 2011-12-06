package Pinto::Action::Unpin;

# ABSTRACT: Untie the index from a particular package

use Moose;
use MooseX::Types::Moose qw(Str);

use Pinto::Types qw(Vers);

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

extends 'Pinto::Action';

#------------------------------------------------------------------------------

has package => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    my $name  =  $self->package();
    my $where = { name => $name, is_pinned => 1 };
    my $pkg   = $self->repos->select_packages($where)->first();

    if (not $pkg) {
        $self->whine("Package $name does not exist or is not pinned");
        return 0;
    }

    $pkg->is_pinned(undef);
    $pkg->update();
    $self->repos->db->mark_latest($pkg);

    return 1;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#------------------------------------------------------------------------------

1;

__END__
