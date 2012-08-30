# ABSTRACT: Base class for Action runners

package Pinto::Runner;

use Moose;

use Try::Tiny;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

has repos => (
    is       => 'ro',
    isa      => 'Pinto::Repository',
    required => 1,
);

#------------------------------------------------------------------------------

with qw( Pinto::Role::Configurable
         Pinto::Role::Loggable );

#------------------------------------------------------------------------------

sub run {
    my ($self, $action) = @_;

    $self->repos->check_schema_version;
    my $result = inner;
    $self->repos->unlock;

    return $result;
};

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------
1;

__END__
