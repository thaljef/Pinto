package Pinto::Role::Log;

# ABSTRACT: Simple logger for Pinto

use Moose::Role;
use Log::Log4perl;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

BEGIN { Log::Log4perl->easy_init() }

#------------------------------------------------------------------------------

has 'log' => (
	is      => 'rw',
	isa     => 'Log::Log4perl::Logger',
	lazy    => 1,
	default => sub { return Log::Log4perl->get_logger(ref($_[0])) }
);

#------------------------------------------------------------------------------

1;

__END__
