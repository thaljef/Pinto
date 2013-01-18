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


has detailed => (
    is        => 'ro',
    isa       => Bool,
    default   => 0,
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

    my $stack = $self->repo->get_stack($self->stack);

    for my $kommit ($stack->history) {

        last if $kommit->is_root_kommit;
        $self->say( trim( $kommit->to_string($self->format) ) . "\n" );

        if ($self->detailed) {
            my @details = $kommit->registration_changes;
            $self->say($_) for (@details ? @details : 'No details available.')
        }
    }

    return $self->result;
}

#------------------------------------------------------------------------------

sub _build_format {
    my ($self) = @_;

    my ($yellow, $reset) = $self->nocolor ? ('', '') 
                                          : (color('bold yellow'), color('reset'));

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
