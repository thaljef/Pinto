package Pinto::TestLogger;

# ABSTRACT: A logger for testing Pinto

use Moose;

extends 'Pinto::Logger';

#-----------------------------------------------------------------------------

has '+config' => (
    required => 0,
);

#-----------------------------------------------------------------------------

override _build_log_level => sub { return 1 };

#-----------------------------------------------------------------------------

override _logit => sub { 
    my ($self, $message) = @_;
    my $fileno = fileno $self->out();

    # Call super() only if it isn't just going to write the messages
    # to STDOUT, because that is what were going to do anyway, and I
    # don't want to see the same messages twice on the console.

    super() if !(defined $fileno) or ($fileno != fileno(STDOUT));
    return print "$message\n";
};

#-----------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#-----------------------------------------------------------------------------
1;

__END__

=head1 DESCRIPTION

L<Pinto::TestLogger> is a subclass of L<Pinto::Logger> than is used
for unit testing the rest of L<Pinto>.  L<Pinto::TestLogger> does not
require a L<Pinto::Config> attribute and the C<log_level> is always 1
(i.e. debug).

=cut
