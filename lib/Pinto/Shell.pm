# ABSTRACT: Shell into a distribution

package Pinto::Shell;

use Moose;
use MooseX::StrictConstructor;
use MooseX::MarkAsMethods ( autoclean => 1 );
use MooseX::Types::Moose qw(Str);

use Pinto::Types qw(File Dir);
use Pinto::Util qw(debug throw);
use Cwd::Guard qw(cwd_guard);

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

has shell => (
    is       => 'ro',
    isa      => Str,
    required => 1,
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

sub spawn {
    my ($self) = @_;

    my $shell = $self->shell;
    my $cwd_guard = cwd_guard( $self->work_dir );
    return system($shell) == 0 ;
}

#-----------------------------------------------------------------------------

1;

__END__
