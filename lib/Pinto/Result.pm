package Pinto::Result;

# ABSTRACT: The result from running a Batch of Actions

use Moose;

use MooseX::Types::Moose qw(Bool ArrayRef);

use overload ('""' => 'to_string');

#-----------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------
# Moose attributes

has changes_made    => (
    is        => 'ro',
    isa       => Bool,
    init_arg  => undef,
    writer    => '_set_changes_made',
    default   => 0,
);

has exceptions => (
    isa        => ArrayRef,
    traits     => [ 'Array' ],
    default    => sub { [] },
    handles    => {
        add_exception => 'push',
        exceptions    => 'elements',
    },
    init_arg   => undef,
);

#-----------------------------------------------------------------------------

sub is_success {
    my ($self) = @_;

    return $self->exceptions() == 0;
}

#-----------------------------------------------------------------------------
# HACK! Confusing: "made_changes" vs. "changes_made"

sub made_changes {
    my ($self) = @_;

    $self->_set_changes_made(1);

    return $self;
}

#-----------------------------------------------------------------------------

sub to_string {
    my ($self) = @_;

    my $string = join "\n", map { "$_" } $self->exceptions();
    $string .= "\n" unless $string =~ m/\n $/x;

    return $string;
}

#-----------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#-----------------------------------------------------------------------------
1;

__END__
