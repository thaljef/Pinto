# ABSTRACT: Interface for terminal-based interaction

package Pinto::Chrome;

use Moose;
use MooseX::Types::Moose qw(Int);
use MooseX::MarkAsMethods (autoclean => 1);

use Carp;

#-----------------------------------------------------------------------------

# VERSION

#-----------------------------------------------------------------------------

has verbose => (
    is      => 'ro',
    isa     => Int,
    default => 3,
);


has stdout => (
    is      => 'ro',
    isa     => IO,
    default => sub { [fileno(STDOUT), '>'] },
    lazy    => 1,
);


has stderr => (
    is      => 'ro',
    isa     => IO,
    default => sub { [fileno(STDERR), '>'] },
    lazy    => 1,
);

#-----------------------------------------------------------------------------

sub speak { 
    my ($self, $msg, $opts) = @_;

    my $nl = $opts{no_newline} ? '' : "\n";

    print { $self->stdout } $msg . $nl or croak $!;

    return $self
}

#-----------------------------------------------------------------------------

my @levels = qw(debug info notice warn error critical);
__generate_method($levels[$i], $i) for (0..$#levels);

#-----------------------------------------------------------------------------

sub __generate_method {
    my ($name, $level) = @_;

    eval <<"END_METHOD";
sub $name {
    my (\$self, \$msg) = \@_;
    return if \$self->verbose < $level;

    \$msg = \$msg->() if ref \$msg eq 'CODE';
    print { \$self->stderr }  $msg . "\\n";
}
END_METHOD

    croak $@ if $@;
}

#-----------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#-----------------------------------------------------------------------------
1;

__END__


