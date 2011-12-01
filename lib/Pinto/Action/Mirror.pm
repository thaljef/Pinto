package Pinto::Action::Mirror;

# ABSTRACT: Pull all the latest distributions into your repository

use Moose;

use URI;
use Try::Tiny;

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------
# ISA

extends 'Pinto::Action';

#------------------------------------------------------------------------------
# Moose Attributes

# has force => (
#    is      => 'ro',
#    isa     => Bool,
#    default => 0,
# );

#------------------------------------------------------------------------------
# Moose Roles

with qw(Pinto::Role::FileFetcher);

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    my $count = 0;
    for my $dist_spec ( $self->repos->cache->contents() ) {

        my $path = $dist_spec->{path};
        my $where = { path => $path };
        if ( $self->repos->db->select_distributions( $where )->count() ) {
            $self->debug("Already have distribution $path.  Skipping it");
            next;
        }

        $count += try   { $self->_do_mirror($dist_spec) }
                  catch { $self->_handle_mirror_error($_) };

    }

    return 0 if not $count;

    $self->add_message("Mirrored $count distributions");

    return 1;
}

#------------------------------------------------------------------------------

sub _do_mirror {
    my ($self, $dist_spec) = @_;

    my $url = URI->new($dist_spec->{source} . '/authors/id/' . $dist_spec->{path});
    my @path_parts = split m{ / }mx, $dist_spec->{path};

    my $destination = $self->repos->root_dir->file( qw(authors id), @path_parts );
    $self->fetch(from => $url, to => $destination);

    my $struct = { path     => $dist_spec->{path},
                   source   => $dist_spec->{source},
                   mtime    => Pinto::Util::mtime($destination),
                   packages => $dist_spec->{packages} };

    $self->repos->add_distribution($struct);

    return 1;
}

#------------------------------------------------------------------------------

sub _handle_mirror_error {
    my ($self, $error)  = @_;

    # TODO: Be more selective about which errors we swallow.  Right
    # now, we swallow any error that came from Pinto.  But all others
    # are fatal.

    if ( blessed($error) && $error->isa('Pinto::Exception') ) {
        $self->add_exception($error);
        $self->whine($error);
        return 0;
    }

    $self->fatal($error);
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#------------------------------------------------------------------------------

1;

__END__
