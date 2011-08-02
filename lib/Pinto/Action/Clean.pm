package Pinto::Action::Clean;

# ABSTRACT: An action to remove cruft from the repository

use Moose;

use File::Find;
use Path::Class;

extends 'Pinto::Action';

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

        my $physical_file = file($File::Find::name);
        my $index_file  = $physical_file->relative($search_dir)->as_foreign('Unix');

        # TODO: Can we just use $_ instead of calling basename() ?
        if (Pinto::Util::is_source_control_file( $physical_file->basename() )) {
            $File::Find::prune = 1;
            return;
        }

        return if not -f $physical_file;
        return if $self->idxmgr()->master_index()->find( file => $index_file );
        $self->logger()->log("Deleting archive $index_file"); # TODO: report as physical file instead?
        push @deleted, $index_file;
        $physical_file->remove(); # TODO: Error check!
    };

    # TODO: Consider using Path::Class::Dir->recurse() instead;
    File::Find::find($wanted, $search_dir);

    return 0 if not @deleted;

    my $message = Pinto::Util::format_message('Deleted archives:', sort @deleted);
    $self->_set_message($message);
    return 1;

}

#------------------------------------------------------------------------------

1;

__END__
