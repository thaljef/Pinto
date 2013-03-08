# ABSTRACT: Filters nothing

package Pinto::PrerequisiteFilter::None;

use Moose;
use MooseX::MarkAsMethods (autoclean => 1);

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

extends qw( Pinto::PrerequisiteFilter );

#------------------------------------------------------------------------------

sub should_filter {
    my ($self, $prereq) = @_;

    return 0;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#-------------------------------------------------------------------------------
1;

__END__
