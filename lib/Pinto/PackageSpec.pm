package Pinto::PackageSpec;

# ABSTRACT: Represents a package name and version

use Moose;

use Carp;
use MooseX::Types::Moose qw(Str Num);
use Pinto::Types qw(Vers);

use overload ('""' => 'to_string', '<=>' => 'compare', fallback => undef);

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

has name => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has version => (
    is       => 'ro',
    isa      => Vers,
    coerce   => 1,
    required => 1,
);


has version_numeric => (
    is       => 'ro',
    isa      => Num,
    init_arg => undef,
    default  => sub { $_[0]->version->numify() },
    lazy     => 1,
);

#------------------------------------------------------------------------------

sub compare {
    my ($this, $that, $swap) = @_;

    my $class = ref $this;
    $that = $class->new( name => $this->name(), version => $that ) if ref $that ne $class;

    ($this, $that) = ($that, $this) if $swap;
    $this->name() eq $that->name() or croak "Cannot compare different packages: $this <=> $that";

    return $this->version() <=> $that->version();
}

#------------------------------------------------------------------------------

sub to_string {
    my ($self) = @_;

    return $self->name() . '-' . $self->version();
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#------------------------------------------------------------------------------
1;

__END__
