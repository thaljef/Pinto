package Pinto::Action::Unpin;

# ABSTRACT: Loosen a package that has been pinned

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
        $self->whine("Package $name does not exist in the repository, or is not pinned");
        return 0;
    }

    $self->info("Unpinning package $pkg");

    $pkg->is_pinned(undef);
    $pkg->update();
    my $latest = $self->repos->db->mark_latest($pkg);

    $self->add_message("Unpinned package $name. Latest is now $latest");

    return 1;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#------------------------------------------------------------------------------

1;

__END__
