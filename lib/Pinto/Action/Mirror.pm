package Pinto::Action::Mirror;

# ABSTRACT: Pull all the latest distributions into your repository

use Moose;

use MooseX::Types::Moose qw(Bool);
use Pinto::Types qw(URI);

use Exception::Class::TryCatch;

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------
# ISA

extends 'Pinto::Action';

#------------------------------------------------------------------------------
# Moose Attributes

has source => (
    is       => 'ro',
    isa      => URI,
    required => 1,
);


has soft => (
   is      => 'ro',
   isa     => Bool,
   default => 0,
);

#------------------------------------------------------------------------------
# Moose Roles

with qw(Pinto::Role::FileFetcher);

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    my $source = $self->source();
    $self->repos->db->load_index($source) unless $self->soft();

    my $where = {source => $source};
    my $foreigners = $self->repos->db->get_distributions($where);

    my $count = 0;
    while ( my $dist = $foreigners->next() ) {

        my $ok = eval { $count += $self->_do_mirror($dist); 1 };

        if ( !$ok && catch my $e, ['Pinto::Exception'] ) {
            $self->add_exception($e);
            $self->whine($e);
            next;
        }
    }

    return 0 if not $count;
    $self->add_message("Mirrored $count distributions from $source");

    return 1;
}

#------------------------------------------------------------------------------

sub _do_mirror {
    my ($self, $dist) = @_;

    my $archive = $dist->archive( $self->config->root_dir() );

    $self->debug("Skipping $archive: already fetched") and return 0 if -e $archive;
    $self->fetch(url => $dist->url(), to => $archive)   or return 0;

    $self->repos->store->add_archive($archive);

    return 1;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#------------------------------------------------------------------------------

1;

__END__
