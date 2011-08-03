package Pinto::Role::Authored;

# ABSTRACT: Something that has an author

use Moose::Role;
use MooseX::Types::Pinto qw(AuthorID);

use Carp;

use namespace::autoclean;

#-----------------------------------------------------------------------------

# VERSION

#-----------------------------------------------------------------------------

requires 'config';

has author => (
    is         => 'ro',
    isa        => AuthorID,
    coerce     => 1,
    lazy_build => 1,
);

sub _build_author {
    my ($self) = @_;
    return $self->config->author()
      or croak 'author attribute is required';
}



#-----------------------------------------------------------------------------

1;

__END__
