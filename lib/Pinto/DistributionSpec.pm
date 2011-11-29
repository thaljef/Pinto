package Pinto::DistributionSpec;

# ABSTRACT: Represents a package name and version

use Moose;

use Carp;
use MooseX::Types::Moose qw(Str);
use Pinto::Types qw(Uri);


#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

has source => (
    is       => 'ro',
    isa      => Uri,
    required => 1,
);


has path => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);


has packages => (
    is         => 'ro',
    isa        => 'ArrayRef[Pinto::PackageSpec]',
    auto_deref => 1,
    required   => 1,
);

#------------------------------------------------------------------------------

sub as_hashref {
    my ($self) = @_;

    my %hash = ( source => $self->source(),
                 path => $self->path(),
                 packages => [ map { $_->as_hashref } $self->packages() ],
    );

    return \%hash;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#------------------------------------------------------------------------------
1;

__END__
