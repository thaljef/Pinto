# ABSTRACT: Represents 

package Pinto::Diff;

use Moose;
use MooseX::MarkAsMethods (autoclean => 1);

use Pinto::Util qw(itis);

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

has raw_diff => (
  is          => 'ro',
  isa         => 'Git::Raw::Diff',
  required    => 1,
);

#------------------------------------------------------------------------------

around BUILDARGS => sub {
  my ($orig, $class, @args) = @_;

  if ( @args == 1 && itis($args[0], 'Git::Raw::Diff') ) {
    return $class->$orig( raw_diff => $args[0] );
  }

  return $class->$orig(@args);
};

#------------------------------------------------------------------------------

sub patch {
    my ($self, $cb) = @_;

    $self->raw_diff->patch($cb);

    return $self;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#-------------------------------------------------------------------------------
1;

__END__
