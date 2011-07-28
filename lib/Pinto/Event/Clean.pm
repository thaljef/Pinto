package Pinto::Event::Clean;

# ABSTRACT: An event to remove cruft from the repository

use Moose;

use File::Find;
use Path::Class;

extends 'Pinto::Event';

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

sub execute {
    my ($self, %args) = @_;
    return;

    my $local = $self->config()->get_required('local');

    my $base_dir = Path::Class::dir($local, qw(authors id));
    return if not -e $base_dir;

    my $wanted = sub {

        my $physical_file = file($File::Find::name);
        my $index_file  = $physical_file->relative($base_dir)->as_foreign('Unix');

        # TODO: Can we just use $_ instead of calling basename() ?
        if (Pinto::Util::is_source_control_file( $physical_file->basename() )) {
            $File::Find::prune = 1;
            return;
        }

        return if not -f $physical_file;
        return if exists $self->master_index()->packages_by_file()->{$index_file};
        $self->log()->info("Cleaning $index_file"); # TODO: report as physical file instead?
        $physical_file->remove(); # TODO: Error check!
    };

    # TODO: Consider using Path::Class::Dir->recurse() instead;
    File::Find::find($wanted, $base_dir);

    my $message = 'Cleaned up archives not found in the index.';
    $self->_set_message($message);

    return $self;

}

#------------------------------------------------------------------------------

1;

__END__
