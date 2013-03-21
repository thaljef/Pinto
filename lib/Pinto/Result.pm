# ABSTRACT: The result from running an Action

package Pinto::Result;

use Moose;
use MooseX::StrictConstructor;
use MooseX::Types::Moose qw(Bool ArrayRef);
use MooseX::MarkAsMethods (autoclean => 1);

use Pinto::Util qw(itis);

use overload (q{""} => 'to_string');

#-----------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

has made_changes => (
    is        => 'ro',
    isa       => Bool,
    writer    => '_set_made_changes',
    default   => 0,
);


has was_successful => (
    is         => 'ro',
    isa        => Bool,
    writer     => '_set_was_successful',
    default    => 1,
);


has exceptions => (
    traits    => [ qw(Array) ],
    handles   => {exceptions => 'elements', add_exception => 'push'},
    isa       => ArrayRef['Pinto::Exception'],
    default   => sub { [] },
);

#-----------------------------------------------------------------------------

sub failed {
    my ($self, %args) = @_;

    $self->_set_was_successful(0);

    if (my $reason = $args{because}) {

        # HACK: Sometimes we'll get exceptions that are strings
        # instead of objects (like from Moose type constraint
        # violations).  So we have to convert them ourselves.
        # If the message already contains a full stack trace,
        # then it will be really ugly.  God I wish Perl had
        # sane native exeptions.

        require Pinto::Exception;
        
        $reason = Pinto::Exception->new(message => $reason) 
            if not itis($reason, 'Pinto::Exception');

        $self->add_exception($reason); 
    }

    return $self;
}

#-----------------------------------------------------------------------------

sub changed {
    my ($self) = @_;

    $self->_set_made_changes(1);

    return $self;
}

#-----------------------------------------------------------------------------

sub exit_status {
    my ($self) = @_;

    return $self->was_successful ? 0 : 1;
}

#-----------------------------------------------------------------------------

sub to_string {
    my ($self) = @_;

    return 'OK' if $self->was_successful;

    if (my @exceptions = $self->exceptions) {
        return join "\n", map { $ENV{PINTO_DEBUG} ? "$_" : $_->message } @exceptions;
    }

    return 'Unknown error';
}

#-----------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#-----------------------------------------------------------------------------
1;

__END__
