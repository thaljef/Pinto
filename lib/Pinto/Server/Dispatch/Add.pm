package Pinto::Server::Dispatch::Add;

# ABSTRACT: Web interface to a Pinto repository

use Path::Class qw(dir);
use File::Temp  qw(tempdir);

use base 'CGI::Application';

use CGI::Application::Plugin::AutoRunmode;

#-----------------------------------------------------------------------------

# VERSION

#-----------------------------------------------------------------------------
my $count = 1;

sub new {
    my ($class, $args) = @_;
    my $self = $class->SUPER::new($args);
    $self->{pinto} = $args->{pinto};
    return $self;
}

sub pinto {
    my ($self) = @_;
    return $self->{pinto};
}

sub add :RunMode {

    print ">>Count is:" . $count++ . "\n";

    my $self = shift;
    $DB::single = 1;
    my $query     = $self->query();
    my $author    = $query->param('author');
    my $dist      = $query->param('dist');
    my $dfh       = $dist->handle();

    if (not $dist) {
        $self->header_add(-status => '400 No distribution file supplied');
        return;
    }

    if (not $author) {
        $self->header_add(-status => '400 No author supplied');
        return;
    }


    my $tmpdir = dir( tempdir(CLEANUP => 1) );
    $DB::single = 1;
    my $tmpfile = $tmpdir->file($dist);
    my $tfh = $tmpfile->openw();

    while ( $dfh->read(my $buffer, 1024) ) { print { $tfh } $buffer }
    $tfh->close();
    $dfh->close();
   

    eval { $self->pinto->add(dists => $tmpfile, author => $author) }
      or return $@;

    $self->header_add(-status => '202 Module added');

    return;
}

#----------------------------------------------------------------------------
1;

__END__
