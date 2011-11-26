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

#------------------------------------------------------------------------------

sub as_hashref {
    my ($self) = @_;

    my %hash = ( name => $self->name(), version => $self->version() );

    return \%hash;
}

#------------------------------------------------------------------------------

sub compare {
    my ($this, $that, $swap) = @_;

    # Note:  I'm not entirely sure this code will work for subclasses

    my $this_class = ref $this;
    my $that_class = ref $that;

    if ( not $that_class )  {
        $that = __PACKAGE__->new( name => $this->name(), version => $that );
    }
    elsif ( blessed($that) && $that->isa('version') ) {
        $that = __PACKAGE__->new( name => $this->name(), version => $that );
    }
    elsif ( !(blessed($that) && $that->can('name') && $that->can('version')) ) {
        croak "Cannot compare $that_class with $this_class";
    }

    croak "Cannot compare different packages: $this <=> $that"
        if $this->name() ne $that->name();

    ($this, $that) = ($that, $this) if $swap;
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
