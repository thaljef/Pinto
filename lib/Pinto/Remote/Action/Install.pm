# ABSTRACT: Install packages from the repository

package Pinto::Remote::Action::Install;

use Moose;
use MooseX::MarkAsMethods (autoclean => 1);
use MooseX::Types::Moose qw(Undef Bool HashRef ArrayRef Maybe Str);

use File::Temp;
use File::Which qw(which);

use Pinto::Result;
use Pinto::Util qw(throw);

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

extends qw( Pinto::Remote::Action Pinto::Role::Installer );

#------------------------------------------------------------------------------

has targets => (
    isa      => ArrayRef[Str],
    traits   => [ 'Array' ],
    handles  => { targets => 'elements' },
    required => 1,
);


has do_pull => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);

#------------------------------------------------------------------------------

override execute => sub {
    my ($self) = @_;

    $self->_do_pull if $self->pull;

    my $result = $self->_install;

    return $result;
 };

#------------------------------------------------------------------------------

sub _do_pull {
    my ($self) = @_;

    # Wedge the target list back into the args hash
    $self->args->{targets} = $self->targets;

    my $request = $self->_make_request(name => 'pull');
    my $result  = $self->_send_request(req => $request);

    throw 'Failed to pull packages' if not $result->was_successful;

    return $self;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#-----------------------------------------------------------------------------
1;

__END__

=for Pod::Coverage BUILD

=cut

