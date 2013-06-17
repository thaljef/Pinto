# ABSTRACT: A class for testing a Pinto server

package Pinto::Server::Tester;

use Moose;
use MooseX::Types::Moose qw(Str Int ArrayRef);

use Carp;
use Test::TCP;
use File::Which;
use Proc::Fork;
use Path::Class qw(dir);

use Pinto::Types qw(File Uri);

use HTTP::Server::PSGI;  # just to make sure we have it

#-------------------------------------------------------------------------------

# VERSION

#-------------------------------------------------------------------------------

extends 'Pinto::Tester';

#-------------------------------------------------------------------------------

=attr pintod_opts( \@args )

Passes additional C<@args> to the F<pintod> command line.  Default is empty.

=cut

has pintod_opts => (
  is         => 'ro',
  isa        => ArrayRef,
  default    => sub { [] },
  lazy       => 1,
);

=attr server_port( $integer )

Sets the port that the server will listen on.  If not specified during
construction, defaults to a randomly generated but open port.

=cut

has server_port => (
  is         => 'ro',
  isa        => Int,
  default    => sub { empty_port() },
  lazy       => 1,
);


=attr server_host( $hostname )

Sets the hostname that the server will bind to.  Defaults to C<localhost>.

=cut

has server_host => (
  is         => 'ro',
  isa        => Str,
  init_arg   => undef,
  default    => 'localhost',
);


=attr server_pid

Returns the process id for the server (if it has been started).  Read-only.

=cut

has server_pid => (
  is         => 'rw',
  isa        => Int,
  init_arg   => undef,
  default    => 0,
);


=attr server_url

Returns the full URL that the server will listen on.  Read-only.

=cut

has server_url => (
  is         => 'ro',
  isa        => Uri,
  init_arg   => undef,
  default    => sub { URI->new('http://' . $_[0]->server_host . ':' . $_[0]->server_port) },
);


=attr pintod_exe

Sets the path to the C<pintod> executable.  If not specified, we will search
in F<./blib/script>, F<./bin>, C<PINTO_HOME>, and finally your C<PATH>  An 
exception is thrown if C<pintod> cannot be found.

=cut

has pintod_exe => (
  is         => 'ro',
  isa        => File,
  builder    => '_build_pintod_exe',
  coerce     => 1,
  lazy       => 1,
);


#-------------------------------------------------------------------------------

sub _build_pintod_exe {
  my ($self) = @_;

  # Look inside the dist directory
  for my $dir ([qw(blib script)], [qw(bin)]) {
    my $pintod = dir( @{$dir} )->file('pintod');
    return $pintod if -e $pintod;
  }

  # Look at PINTO_HOME
  return dir($ENV{PINTO_HOME})->file(qw(bin pintod)) 
    if $ENV{PINTO_HOME};

  # Look anywhere in PATH
  return which('pintod')
    || croak 'Unable to find pintod anywhere';

}

#-------------------------------------------------------------------------------

=method start_server()

Starts the L<pintod> server.  Emits a warning if the server is already started.

=cut

sub start_server {
  my ($self) = @_;

  carp 'Server already started' and return if $self->server_pid;

  local $ENV{PLACK_ENV}    = 'testing';            # Suppresses startup message
  local $ENV{PLACK_SERVER} = 'HTTP::Server::PSGI'; # Basic non-forking server
  local $ENV{PINTO_LOCKFILE_TIMEOUT} = 2;          # Don't make tests wait!

  run_fork {

    child {
      my $xtra_lib = $self->_extra_lib;
      my $xtra_opts = $self->pintod_opts;
      my %opts = ('--port' => $self->server_port, '--root' => $self->root);
      my @cmd = ($^X, $xtra_lib, $self->pintod_exe, %opts, @{$xtra_opts});
      $self->tb->note(sprintf 'exec(%s)', join ' ', @cmd);
      exec @cmd;
    }

    parent {
      my $server_pid = shift;
      $self->server_pid($server_pid);
      sleep 5; # Let the server warm up

    }

    error {
        croak "Failed to fork: $!";
    }
  };
 
  return $self;
}

#-------------------------------------------------------------------------------

=method stop_server()

Stops the L<pintod> server.  Emits a warning if the server is not
currently running.

=cut

sub stop_server {
  my ($self) = @_;

  my $server_pid = $self->server_pid;
  carp 'Server was never started' and return if not $server_pid;
  carp "Server $server_pid not running" and return if not kill 0, $server_pid;

  # TODO: Consider using Proc::Terminator instead
  kill 'TERM', $server_pid;
  sleep 5 and waitpid $server_pid, 0;

  return $self;
}

#-------------------------------------------------------------------------------

=method server_running_ok()

Asserts that the server is running.

=cut

sub server_running_ok {
  my ($self) = @_;

  my $server_pid  = $self->server_pid;
  my $server_port = $self->server_port;

  my $ok = kill 0, $server_pid; # Is this portable?

  return $self->tb->ok($ok, "Server $server_pid is running on port $server_port");
}

#-------------------------------------------------------------------------------

=method server_not_running_ok

Asserts that the server is not running.

=cut

sub server_not_running_ok {
  my ($self) = @_;

  my $server_pid = $self->server_pid;
  my $ok = not kill 0, $server_pid;  # Is this portable?

  return $self->tb->ok($ok, "Server is not running with pid $server_pid");
}

#-------------------------------------------------------------------------------

sub _extra_lib {
  my ($self) = @_;

  my $blib = dir( qw(blib lib) );
  my $lib  = dir( qw(     lib) );

  return "-I$blib" if -e $blib;
  return "-I$lib"  if -e $lib;
  return '';
}

#-------------------------------------------------------------------------------

sub DEMOLISH {
  my ($self) = @_;

  $self->stop_server if $self->server_pid;

  return;
}

#-------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#-------------------------------------------------------------------------------

1;

__END__

=pod

=for stopwords responder

=for Pod::Coverage DEMOLISH

=cut
