# ABSTRACT: Show revision log for a stack

package Pinto::Action::Log;

use Moose;
use MooseX::Types::Moose qw(Bool Int Undef Str);

use Term::ANSIColor;

use Pinto::Util qw(trim);
use Pinto::Types qw(StackName StackDefault);
use Pinto::Exception qw(throw);

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

extends qw( Pinto::Action );

#------------------------------------------------------------------------------

has stack => (
    is        => 'ro',
    isa       => StackName | StackDefault,
    default   => undef,
);


has revision => (
    is        => 'ro',
    isa       => Int | Undef,
    default   => undef,
);


has format => (
    is      => 'ro',
    isa     => Str,
    builder => '_build_format',
    lazy    => 1,
);


has nocolor => (
    is        => 'ro',
    isa       => Bool,
    default   => 0,
);

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    # Print the head
    my head = $self->repo->get_stack($self->stack)->head;
    $self->say( trim( $head->to_string($self->format) ) ) . "\n";

    # Print all ancestors
    my $rs = $head->ancestors;
    while (my $kommit = $rs->next) {
        last if $kommit->is_root_kommit;
        $self->say( trim( $kommit->to_string($self->format) ) . "\n" );
    }

    return $self->result;
}

#------------------------------------------------------------------------------

sub _build_format {
    my ($self) = @_;

    my $yellow = $self->nocolor ? '' : color('bold yellow');
    my $reset  = $self->nocolor ? '' : color('reset');

    return <<"END_FORMAT";
${yellow}commit %I${reset}
Date:   %u
Author: %j 

%g
END_FORMAT

}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------

1;

__END__
