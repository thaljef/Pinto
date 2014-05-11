# ABSTRACT: Install packages from the repository

package Pinto::Remote::Action::Install;

use Moose;
use MooseX::MarkAsMethods ( autoclean => 1 );
use MooseX::Types::Moose qw(Undef Bool HashRef ArrayRef Maybe Str);

use File::Temp;
use File::Which qw(which);
use Term::ANSIColor;

use Pinto::Result;
use Pinto::Util qw(throw);
use Pinto::Constants qw(:protocol);

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

extends qw( Pinto::Remote::Action );

#------------------------------------------------------------------------------

has targets => (
    isa => ArrayRef [Str],
    traits  => ['Array'],
    handles => { targets => 'elements' },
    default => sub { $_[0]->args->{targets} || [] },
    writer  => '_targets',
    lazy    => 1,
);

has do_pull => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);

has mirror_uri => (
    is      => 'ro',
    isa     => Str,
    builder => '_build_mirror_uri',
    lazy    => 1,
);

has all => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);

#------------------------------------------------------------------------------

sub _build_mirror_uri {
    my ($self) = @_;

    my $stack      = $self->args->{stack};
    my $stack_dir  = defined $stack ? "/stacks/$stack" : '';
    my $mirror_uri = $self->root . $stack_dir;

    if ( defined $self->password ) {

        # Squirt username and password into URI
        my $credentials = $self->username . ':' . $self->password;
        $mirror_uri =~ s{^ (https?://) }{$1$credentials\@}mx;
    }

    return $mirror_uri;
}

#------------------------------------------------------------------------------

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;

    my $args = $class->$orig(@_);

    # Intercept attributes from the action "args" hash
    $args->{all}           = delete $args->{args}->{all}           || 0;
    $args->{do_pull}       = delete $args->{args}->{do_pull}       || 0;
    $args->{cpanm_options} = delete $args->{args}->{cpanm_options} || {};

    return $args;
};

#------------------------------------------------------------------------------
# Pinto::Role::Installer will handle installation after execute()

override execute => sub {
    my ($self) = @_;

    $self->_pull_targets    if $self->do_pull;
    $self->_get_all_targets if $self->all;

    return Pinto::Result->new;
};

#------------------------------------------------------------------------------

sub _pull_targets {
    my ($self) = @_;

    my $request = $self->_make_request( name => 'pull' );
    my $result = $self->_send_request( req => $request );

    throw 'Failed to pull packages' if not $result->was_successful;

    return $result;
}

#------------------------------------------------------------------------------

sub _get_all_targets {
    my ($self) = @_;

    # This is a total hack because Pinto::Server doesn't have an API yet.  So
    # we have to do crazy stuff like strip color from the command output to
    # make it machine-readable.

    delete $self->args->{targets};
    $self->args->{format} = '%p';

    my $request = $self->_make_request( name => 'list' );
    my $response = $self->request( $request );

    throw 'Failed to get target list' if not $response->is_success;

    my @lines = split "\n", Term::ANSIColor::colorstrip($response->content);
    my @targets = grep { $_ !~ $PINTO_PROTOCOL_DIAG_PREFIX } @lines;
    $self->_targets(\@targets);

    return $self;
}

#------------------------------------------------------------------------------

with qw( Pinto::Role::Installer );

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#-----------------------------------------------------------------------------
1;

__END__

=for Pod::Coverage BUILD

=cut

