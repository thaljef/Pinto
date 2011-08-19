package Pinto::Action::Clean;

# ABSTRACT: An action to remove cruft from the repository

use Moose;

use File::Find;
use Path::Class;

extends 'Pinto::Action';

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

override execute => sub {
    my ($self) = @_;

    my $repos      = $self->config()->repos();
    my $search_dir = Path::Class::dir($repos, qw(authors id));
    return 0 if not -e $search_dir;

    my @removed = ();
    my $wanted = $self->_make_callback($search_dir, \@removed);
    File::Find::find($wanted, $search_dir);
    return 0 if not @removed;

    $self->add_message( "Removed unindexed distribution $_" ) for @removed;

    return 1;
};

#------------------------------------------------------------------------------

sub _make_callback {
    my ($self, $search_dir, $deleted) = @_;

    return sub {

        if ( Pinto::Util::is_source_control_file($_) ) {
            $File::Find::prune = 1;
            return;
        }

        return if not -f $File::Find::name;

        my $file = file($File::Find::name);
        my $location  = $file->relative($search_dir)->as_foreign('Unix');
        return if $self->idxmgr->master_index->distributions->{$location};

        $self->store->remove(file => $file);
        push @{ $deleted }, $location;
    };
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#------------------------------------------------------------------------------

1;

__END__
