# ABSTRACT: Base class for mergers

package Pinto::Merger;

use Moose;
use MooseX::Types::Moose qw(HashRef);
use MooseX::MarkAsMethods (autoclean => 1);

use Pinto::Exception qw(throw);

#-----------------------------------------------------------------------------

# VERSION

#-----------------------------------------------------------------------------

with qw(Pinto::Role::Loggable);

#-----------------------------------------------------------------------------

has from_stack => (
    is       => 'ro',
    isa      => 'Pinto::Schema::Result::Stack',
    required => 1,
);


has to_stack => (
    is       => 'ro',
    isa      => 'Pinto::Schema::Result::Stack',
    required => 1,
);


has repo    => (
	is       => 'ro',
	isa      => 'Pinto::Repository',
	required => 1,
);


has options => (
    is       => 'ro',
    isa      => HashRef,
    default  => sub { {} },
);

#-----------------------------------------------------------------------------

sub merge { throw "Abstract method" }

#-----------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#-----------------------------------------------------------------------------

1;

__END__

=head1 LOGGING METHODS

The following methods are available for writing to the logs at various
levels (listed in order of increasing priority).  Each method takes a
single message as an argument.

=over

=item debug

=item info

=item notice

=item warning

=item error

=item fatal

Note that C<fatal> causes the application to throw an exception.

=back

=cut
