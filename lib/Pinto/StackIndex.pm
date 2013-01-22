# ABSTRACT: TODO

package Pinto::StackIndex;

use Moose;

use File::Touch;

use Pinto::Types qw(File);

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

has file  => (
    is       => 'ro',
    isa      => File,
    required => 1,
);

#------------------------------------------------------------------------------

sub write {
    my ($self) = @_;

    my $file = $self->file;
    touch("$file") or die $!;

    return $self;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------

1;

__END__





