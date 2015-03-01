# ABSTRACT: Unpack and open a distribution with your shell

package Pinto::Action::Look;

use Moose;
use MooseX::StrictConstructor;
use MooseX::MarkAsMethods ( autoclean => 1 );
use MooseX::Types::Moose qw(Str);

use Pinto::Util qw(throw);
use Pinto::Types qw(TargetList);
use Pinto::Shell;

use Path::Class qw(file);

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

extends qw( Pinto::Action );

#------------------------------------------------------------------------------

has targets => (
    isa      => TargetList,
    traits   => [qw(Array)],
    handles  => { targets => 'elements' },
    required => 1,
    coerce   => 1,
);

has shell => (
    is       => 'ro',
    isa      => Str,
);

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    my $shell = $self->shell || $ENV{SHELL};
    $shell ||= $ENV{COMSPEC} if $^O eq 'MSWin32';

    $shell or throw "You don't seem to have a SHELL :/";

    $shell = file($shell)->resolve()
      or throw "Can't resolve the path to your SHELL";

    -x $shell or throw "Your SHELL does not appear to be executable";

    for my $target ( $self->targets ) {
        my $dist = $self->repo->get_distribution( target => $target )
          or throw "$target is not in your repository";

        my $path = file($dist->author, $dist->vname);
        $self->diag("Entering $path with $shell\n");

        Pinto::Shell->new( shell => $shell, archive => $dist->native_path )->spawn();
    }

    return $self->result;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------

1;

__END__
