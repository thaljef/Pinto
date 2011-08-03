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

sub execute {
    my ($self) = @_;

    my $local      = $self->config()->local();
    my $search_dir = Path::Class::dir($local, qw(authors id));
    return 0 if not -e $search_dir;

    my @deleted = ();
    my $wanted = sub {

        if (Pinto::Util::is_source_control_file( $_ )) {
            $File::Find::prune = 1;
            return;
        }

        return if not -f $File::Find::name;
        my $physical_file = file($File::Find::name);
        my $index_file  = $physical_file->relative($search_dir)->as_foreign('Unix');
        return if $self->idxmgr()->master_index()->find( file => $index_file );

        $self->logger()->log("Deleting archive $index_file"); # TODO: report as physical file instead?
        $physical_file->remove(); # TODO: Error check!
        push @deleted, $index_file;
    };

    File::Find::find($wanted, $search_dir);

    return 0 if not @deleted;

    my $message = Pinto::Util::format_message('Deleted archives:', sort @deleted);
    $self->_set_message($message);
    return 1;

}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#------------------------------------------------------------------------------

1;

__END__
