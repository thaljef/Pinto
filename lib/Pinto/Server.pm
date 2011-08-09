package Pinto::Server;

# ABSTRACT: Web interface to a Pinto repository

use Moose;

use Pinto;

use File::Temp;

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
    $self->header_add(-status => '501 Not Implemented');

    my $query     = $self->query();
    my $author    = $query->param('author');
    my $filename  = $query->param('filename');
    my $filedata  = $query->param('file');

    if (not $filedata) {
        $self->header_add(-status => '400 No distribution file data supplied');
        return;
    }


    if (not $filename) {
        $self->header_add(-status => '400 No distribution file name supplied');
        return;
    }


    if (not $author) {
        $self->header_add(-status => '400 No author supplied');
        return;
    }


    my $tmp = File::Temp->new();
    while ( read($filedata, my $buffer, 1024) ) { print { $tmp } $buffer }
    $tmp->close();

    $self->pinto->add( author => $author, file => $tmp->filename() );
    $self->header_add(-status => '202 Module added');

    return;
}

#----------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#----------------------------------------------------------------------------
1;

__END__
