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

extends qw( Pinto::Remote::Action );

#------------------------------------------------------------------------------

has targets => (
    isa      => ArrayRef[Str],
    traits   => [ 'Array' ],
    handles  => { targets => 'elements' },
    default  => sub { $_[0]->args->{targets} || [] },
    lazy     => 1,
);


has do_pull => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);


has mirror_url => (
    is      => 'ro',
    isa     => Str,
    builder => '_build_mirror_url',
    lazy    => 1,
);

#------------------------------------------------------------------------------

sub _build_mirror_url {
    my ($self) = @_;

    my $stack      = $self->args->{stack};
    my $stack_dir  = defined $stack ? "/stacks/$stack" : '';
    my $mirror_url = $self->root . $stack_dir;

    return $mirror_url;
}

#------------------------------------------------------------------------------

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;

    my $args = $class->$orig(@_);

    # Intercept attributes from the action "args" hash
    $args->{do_pull}       = delete $args->{args}->{do_pull}       || 0;
    $args->{cpanm_options} = delete $args->{args}->{cpanm_options} || {};

    return $args;
};

#------------------------------------------------------------------------------

override execute => sub {
    my ($self) = @_;

    my $result;
    if ($self->do_pull) {

        my $request = $self->_make_request(name => 'pull');
        $result = $self->_send_request(req => $request);

        throw 'Failed to pull packages' if not $result->was_successful;
    }

    # Pinto::Role::Installer will handle installation after execute()
    return $result;
 };

#------------------------------------------------------------------------------

with qw( Pinto::Role::Installer );

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#-----------------------------------------------------------------------------
1;

__END__

=for Pod::Coverage BUILD

=cut

