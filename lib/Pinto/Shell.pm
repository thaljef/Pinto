# ABSTRACT: Shell into a distribution

package Pinto::Shell;

use Moose;
use MooseX::StrictConstructor;
use MooseX::MarkAsMethods ( autoclean => 1 );
use MooseX::Types::Moose qw(Str);

use Pinto::Util qw(throw);
use Pinto::Types qw(File Dir);

use Path::Class qw(file);
use Cwd::Guard qw(cwd_guard);

use overload ( q{""} => 'to_string' );

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

has shell => (
    is       => 'ro',
    isa      => File,
    builder  => '_build_shell',
);

has archive => (
    is       => 'ro',
    isa      => File,
    required => 1,
);

has unpacker => (
    is       => 'ro',
    isa      => 'Pinto::ArchiveUnpacker',
    default  => sub { Pinto::ArchiveUnpacker->new( archive => $_[0]->archive ) },
    init_arg => undef,
    lazy     => 1,
);

has work_dir => (
    is       => 'ro',
    isa      => Dir,
    default  => sub { $_[0]->unpacker->unpack },
    init_arg => undef,
    lazy     => 1,
);

#------------------------------------------------------------------------------

sub _build_shell {

    my $shell = $ENV{PINTO_SHELL} || $ENV{SHELL} || $ENV{COMSPEC}
        or throw "You don't seem to have a SHELL";

    my $shell_resolved = eval { file($shell)->resolve }
        or throw "Can't resolve the path to your SHELL $shell";

    -x $shell_resolved
        or throw "Your SHELL $shell is not executable";

    return $shell_resolved;
}

#------------------------------------------------------------------------------

sub spawn {
    my ($self) = @_;

    my $cwd_guard = cwd_guard( $self->work_dir );

    # TODO: This probably isn't very portable, especially if the
    # shell command contains spaces or special characters. We
    # probably need to shell-quote the command and pass a list.

    return system("$self") == 0;
}

#-----------------------------------------------------------------------------

sub to_string {
    my ($self) = @_;

    return $self->shell->stringify;
}
#-----------------------------------------------------------------------------

1;

__END__
