# ABSTRACT: Force a package to stay in a stack

package Pinto::Action::Look;

use Moose;
use MooseX::StrictConstructor;
use MooseX::MarkAsMethods ( autoclean => 1 );
use MooseX::Types::Moose qw(Str);

use Pinto::Util qw(throw);
use Pinto::Types qw(TargetList);
use Pinto::Shell;

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

    for my $target ( $self->targets ) {
        my $dist = $self->repo->get_distribution( target => $target )
          or throw "$target is not in your repository";

        my $shell = $self->shell || $ENV{SHELL};
        $shell ||= $ENV{COMSPEC} if $^O eq 'MSWin32';

        if ($shell) {
            my $path = join '/', $dist->author, $dist->vname;
            $self->diag("Entering $path with $shell\n");
            Pinto::Shell->new( shell => $shell, archive => $dist->native_path )->spawn();
        }
        else {
            throw "You don't seem to have a SHELL :/";
        }
    }

    return $self->result;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------

1;

__END__
