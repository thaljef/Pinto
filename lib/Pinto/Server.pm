package Pinto::Server;

# ABSTRACT: Web interface to a Pinto repository

use Moose;

use Pinto;

use Path::Class qw(dir);
use File::Temp  qw(tempdir);

use base 'CGI::Application';

use CGI::Application::Plugin::AutoRunmode;

#-----------------------------------------------------------------------------

# VERSION

#-----------------------------------------------------------------------------

has 'pinto'  => (
    is         => 'ro',
    isa        => 'Pinto',
    lazy_build => 1,,
);

#-----------------------------------------------------------------------------

sub _build_pinto {
    my ($self) = @_;

    my $config = Pinto::Config->new();
    my $logger = Pinto::Logger->new();
    my $pinto  = Pinto->new(config => $config, logger => $logger);

    return $pinto;
}

#-----------------------------------------------------------------------------

sub add :Runmode {
    my $self = shift;

    $DB::single = 1;

    my $query     = $self->query();
    my $author    = $query->param('author');
    my $file      = $query->param('file');

    if (not $file) {
        $self->header_add(-status => '400 No distribution file supplied');
        return;
    }

    if (not $author) {
        $self->header_add(-status => '400 No author supplied');
        return;
    }


    my $tmpdir = dir( tempdir(CLEANUP => 1) );
    my $tmpfile = $tmpdir->file($file);
    my $fh = $tmpfile->openw();

    while ( read($file, my $buffer, 1024) ) { print { $fh } $buffer }
    $fh->close();

    my $ok = eval { $self->pinto->add( file   => $tmpfile,
                                       author => $author ); 1 };

    my $status = $ok ? '202 Module added' : "500 Error: $@";
    $self->header_add(-status => $status);

    return;
}

#----------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#----------------------------------------------------------------------------
1;

__END__
