# ABSTRACT: Compute difference between two revisions

package Pinto::Difference;

use Moose;
use MooseX::MarkAsMethods (autoclean => 1);

use Array::Diff;

use overload ( q{""} => 'to_string' );

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

has left => (
    is       => 'ro',
    isa      => 'Pinto::Schema::Result::Revision',
    required => 1,
);


has right => (
    is       => 'ro',
    isa      => 'Pinto::Schema::Result::Revision',
    required => 1,
);


has _diff => (
    init_arg  => undef,
    handles   => [ qw(added deleted) ],
    builder   => '_build_diff',
    lazy      => 1,
);


#------------------------------------------------------------------------------

with qw( Pinto::Role::Colorable );

#------------------------------------------------------------------------------

sub _build_diff {
    my ($self) = @_;

    my @left  = sort {$a cmp $b } $self->left->registrations;
    my @right = sort {$a cmp $b } $self->right->registrations;

    return Array::Diff->diff(\@left, \@right);
}

#------------------------------------------------------------------------------

sub to_string {
    my ($self) = @_;

    my $string = '';
    my $format = "%m%s%y %-40p %12v %a/%f\n";

    for my $added (@{ $self->added }) {
        my $line = '+' . $added->to_string($format);
        my $color  = $self->color_1;
        $string .= $self->colorize_with_color($line, $color);
    }

    for my $deleted (@{ $self->deleted }) {
        my $line = '-' . $deleted->to_string($format);
        my $color  = $self->color_3;
        $string .= $self->colorize_with_color($line, $color);
    }

    # TODO: Group output lines into a sensible order

    return $string;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------
1;

__END__
