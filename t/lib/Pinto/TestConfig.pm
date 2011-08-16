package Pinto::TestConfig;

# ABSTRACT: A Pinto::Config for testing

use Moose;

extends 'Pinto::Config';

#-----------------------------------------------------------------------------

override _build_config_file => sub { return };

override _build_author => sub { return 'AUTHOR' };

#-----------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#-----------------------------------------------------------------------------
1;

__END__

=head1 DESCRIPTION

L<Pinto::TestConfig> is a subclass of L<Pinto::Config> that is used
for unit testing the rest of L<Pinto>.  L<Pinto::TestConfig> will
never try to read an actual configuration file, so you must provide
any required attributes explicitly.  Also, the C<author> attribute
will always be "AUTHOR".

=cut
