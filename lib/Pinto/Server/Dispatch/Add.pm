package Pinto::Server::Dispatch::Add;

# ABSTRACT: Web interface to a Pinto repository

use Moose;

use Path::Class qw(dir);
use File::Temp  qw(tempdir);

use base 'CGI::Application';

use CGI::Application::Plugin::AutoRunmode;

#-----------------------------------------------------------------------------

# VERSION

#-----------------------------------------------------------------------------

has pinto => (
    is       => 'ro',
    isa      => 'Pinto',
    required => 1,
);

#-----------------------------------------------------------------------------

sub add :RunMode {

    my $self = shift;

    my $query     = $self->query();
    my $author    = $query->param('author');
    my $dist      = $query->param('dist');

    if (not $dist) {
        $self->header_add(-status => '400 No distribution file supplied');
        return;
    }

    if (not $author) {
        $self->header_add(-status => '400 No author supplied');
        return;
    }


    my $tmpdir = dir( tempdir(CLEANUP => 1) );
    my $tmpfile = $tmpdir->file($dist);
    my $fh = $tmpfile->openw();

    while ( read($dist, my $buffer, 1024) ) { print { $fh } $buffer }
    $fh->close();

    eval { $self->pinto->add(dists => $tmpfile, author => $author); 1 }
      or return $self->error_runmode($@);

    $self->header_add(-status => '202 Module added');

    return;
}

#----------------------------------------------------------------------------

sub error_runmode {
  my ($self, $error) = @_;
  $self->header_add(-status => '500 Server Error');
  return "MY ERRORS: $error";
}

#----------------------------------------------------------------------------

#__PACKAGE__->meta->make_immutable();

#----------------------------------------------------------------------------
1;

__END__
