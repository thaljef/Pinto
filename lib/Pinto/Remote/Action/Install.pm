# ABSTRACT: Install packages from the repository

package Pinto::Remote::Action::Install;

use Moose;
use MooseX::MarkAsMethods (autoclean => 1);
use MooseX::Types::Moose qw(Undef Bool HashRef ArrayRef Maybe Str);

use File::Temp;
use File::Which qw(which);

use Pinto::Util qw(throw);

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

extends qw( Pinto::Remote::Action );

#------------------------------------------------------------------------------

has cpanm_options => (
    is      => 'ro',
    isa     => HashRef[Maybe[Str]],
    default => sub { $_[0]->args->{cpanm_options} || {} },
    lazy    => 1,
);


has cpanm_exe => (
    is      => 'ro',
    isa     => Str,
    default => sub { which('cpanm') || throw 'Could not find cpanm in PATH' },
    lazy    => 1,
);


has targets => (
    isa      => ArrayRef[Str],
    traits   => [ 'Array' ],
    handles  => { targets => 'elements' },
    default  => sub { $_[0]->args->{targets} || [] },
);


has pull => (
    is       => 'ro',
    isa      => Bool,
    default  => sub { $_[0]->args->{pull} || 0 },
);

#------------------------------------------------------------------------------

sub BUILD {
    my ($self) = @_;

    my $cpanm_exe = $self->cpanm_exe;

    my $cpanm_version_cmd = "$cpanm_exe --version";
    my $cpanm_version_cmd_output = qx{$cpanm_version_cmd};  ## no critic qw(Backtick)
    throw "Could not learn version of cpanm: $!" if $?;

    my ($cpanm_version) = $cpanm_version_cmd_output =~ m{version \s+ ([\d.]+)}x
      or throw "Could not parse cpanm version number from $cpanm_version_cmd_output";

    my $min_cpanm_version = '1.5013';
    if ($cpanm_version < $min_cpanm_version) {
      throw "Your cpanm ($cpanm_version) is too old. Must have $min_cpanm_version or newer";
    }

    # HACK: Prior versions of Pinto had an index file for the default stack
    # in the modules/ directory at the root of the repository.  So if you
    # pointed cpanm at the repository root, you'd get stuff from the default
    # stack.  But this is no longer true.  Now, each request for a file
    # from the repository must specify a stack.  We could possibly work
    # around this by sending another request to find out the default stack
    # is called.  But for now, I'm just going to punt.

    $self->args->{stack}
      or throw 'Must specify a stack to install from a remote repository';

    return $self;
}

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


    my $request = $self->_make_request(name => 'pull');
    my $result  = $self->_send_request(req => $request);

    throw 'Failed to pull packages' if not $result->was_successful;

    return $self;
}

#------------------------------------------------------------------------------

sub _install {
    my ($self, $index) = @_;

    # Wire cpanm to the index
    my $opts  = $self->cpanm_options;
    my $stack = $self->args->{stack};
    $opts->{mirror}        = $self->config->root->as_string . '/' . $stack;
    $opts->{'mirror-only'} = '';

    # Process other cpanm options
    my @cpanm_opts;
    for my $opt ( keys %{ $opts } ){
        my $dashes = (length $opt == 1) ? '-' : '--';
        my $dashed_opt = $dashes . $opt;
        my $opt_value = $opts->{$opt};
        push @cpanm_opts, $dashed_opt;
        push @cpanm_opts, $opt_value if defined $opt_value && length $opt_value;
    }

    # Run cpanm
    $self->debug(join ' ', 'Running:', $self->cpanm_exe, @cpanm_opts);
    0 == system($self->cpanm_exe, @cpanm_opts, $self->targets)
      or throw "Installation failed.  See the cpanm build log for details";

    return Pinto::Remote::Result->new(was_successful => 1);
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#-----------------------------------------------------------------------------
1;

__END__

=for Pod::Coverage BUILD

=cut

