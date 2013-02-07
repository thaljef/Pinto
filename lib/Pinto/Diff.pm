# ABSTRACT: Represents difference between two stacks

package Pinto::Diff;

use Moose;
use MooseX::MarkAsMethods (autoclean => 1);

use Pinto::Util qw(itis);

use overload ( '""' => 'to_string' );

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

has raw_diff => (
  is          => 'ro',
  isa         => 'Git::Raw::Diff',
  required    => 1,
);

#------------------------------------------------------------------------------

sub patch {
    my ($self, $cb) = @_;

    $self->raw_diff->patch($cb);

    return $self;
}

#------------------------------------------------------------------------------

sub to_string {
    my ($self) = @_;

    my $buffer = '';
    my $cb = sub {
        my ($type, $patch_line) = @_;
        return if $type =~ m/(ctx|file|hunk|bin)/;
        $buffer .= $patch_line;
    };

    $self->patch($cb);

    return $buffer;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#-------------------------------------------------------------------------------
1;

__END__
