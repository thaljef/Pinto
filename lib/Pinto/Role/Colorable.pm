# ABSTRACT: Something that wants to colorize strings

package Pinto::Role::Colorable;

use Moose::Role;
use MooseX::Types::Moose qw(Str Bool ArrayRef);
use MooseX::MarkAsMethods (autoclean => 1);

use Term::ANSIColor qw(color colorvalid);

use Pinto::Exception qw(throw);

#-----------------------------------------------------------------------------

# VERSION

#-----------------------------------------------------------------------------

has nocolor => (
    is         => 'ro',
    isa        => Bool,
    default    => sub { $ENV{PINTO_NO_COLOR} || $ENV{PINTO_NO_COLOUR} || 0 },
);


has color_0 => (
	is        => 'ro',
	isa       => Str,
	default   => sub { color('reset') },
);


has color_1 => (
	is        => 'ro',
	isa       => Str,
	default   => sub { color($_[0]->user_colors->[0] || 'green') },
	lazy      => 1,
);


has color_2 => (
	is        => 'ro',
	isa       => Str,
	default   => sub { color($_[0]->user_colors->[1] || 'yellow') },
	lazy      => 1,
);


has color_3 => (
	is        => 'ro',
	isa       => Str,
	default   => sub { color($_[0]->user_colors->[2] || 'red') },
	lazy      => 1,
);


has user_colors => (
	is        => 'ro',
	isa       => ArrayRef,
	default   => sub { [split m/\s*,\s*/, $ENV{PINTO_COLORS} || $ENV{PINTO_COLOURS} || ''] },
	lazy      => 1,
);

#-----------------------------------------------------------------------------

sub colorize_with_color {
	my ($self, $string, $color) = @_;

	return $string if not $color;
	return $string if $self->nocolor;
	return $color . $string . $self->color_0;
}

#-----------------------------------------------------------------------------

sub colorize_with_color_1 {
	my ($self, $string) = @_;

	return $string if $self->nocolor;
	return $self->color_1 . $string . $self->color_0;
}

#-----------------------------------------------------------------------------

sub colorize_with_color_2 {
	my ($self, $string) = @_;

	return $string if $self->nocolor;
	return $self->color_2 . $string . $self->color_0;
}

#-----------------------------------------------------------------------------

sub colorize_with_color_3 {
	my ($self, $string) = @_;

	return $string if $self->nocolor;
	return $self->color_3 . $string . $self->color_0;
}

#-----------------------------------------------------------------------------

sub BUILD {
    my ($self) = @_;

	colorvalid($_) || throw "User color $_ is not valid" for @{ $self->user_colors };

	return $self;
};

#-----------------------------------------------------------------------------
1;

__END__
