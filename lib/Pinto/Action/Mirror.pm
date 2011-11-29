package Pinto::Action::Mirror;

# ABSTRACT: Pull all the latest distributions into your repository

use Moose;

use URI;
use Path::Class;
use MooseX::Types::Moose qw(Bool);
use Pinto::Types qw(Uri);

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
    isa      => Uri,
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

    my $count = 0;
    for my $dist ( $self->repos->cache->contents() ) {

      my $path = $dist->path();
      my $where = { path => $path };
      if ( $self->repos->db->select_distributions( $where )->count() ) {
          $self->debug("Already have distribution $path.  Skipping it");
          next;
      }

      $count += $self->_do_mirror($dist);

#         my $ok = eval { $count += $self->_do_mirror($dist); 1 };

#         if ( !$ok && catch my $e, ['Pinto::Exception'] ) {
#             $self->add_exception($e);
#             $self->whine($e);
#             next;
#         }
    }

    return 0 if not $count;
    $self->add_message("Mirrored $count distributions");

    return 1;
}

#------------------------------------------------------------------------------

sub _do_mirror {
    my ($self, $dist) = @_;

    my $url = URI->new($dist->source() . '/authors/id/' . $dist->path);
    my @path_parts = split m{ / }mx, $dist->path();
    my $archive = file($self->config->root_dir(), qw(authors id), @path_parts);

    $self->debug("Skipping $archive: already fetched") and return 0 if -e $archive;
    $self->fetch(url => $url, to => $archive)   or return 0;

    $DB::single = 1;
    $self->repos->db->create_distribution($dist);
    $self->repos->store->add_archive($archive);

    return 1;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#------------------------------------------------------------------------------

1;

__END__
