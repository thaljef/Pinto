# ABSTRACT: Add a distribution to a the repository

package Pinto::Remote::Action::Add;

use Moose;
use MooseX::MarkAsMethods (autoclean => 1);

use JSON;

use Pinto::Util qw(throw);

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

extends qw( Pinto::Remote::Action );

#------------------------------------------------------------------------------

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;

    my $args = $class->$orig(@_);

    # I don't have a separate attribute for each action argument, 
    # so I need to wedge in the default author identity somehow.
    # And if PINTO_AUTHOR_ID isn't defined either, then the server
    # will fall back to using the username.  Perhaps I could also
    # do the same thing here just to make it clear what's going on.
    
    $args->{args}->{author} ||= $ENV{PINTO_AUTHOR_ID} if $ENV{PINTO_AUTHOR_ID};

    return $args;
};

#------------------------------------------------------------------------------

sub BUILD {
    my ($self) = @_;

    throw 'Only one archive can be remotely added at a time'
      if @{ $self->args->{archives} || [] } > 1;

    return $self;
}

#------------------------------------------------------------------------------

override _make_request_body => sub {
    my ($self) = @_;

    my $body = super;
    my $archive = (delete $self->args->{archives})->[0];
    push @{ $body }, (archives => [$archive]);

    return $body;
};

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------
1;

__END__

=for Pod::Coverage BUILD

=cut

