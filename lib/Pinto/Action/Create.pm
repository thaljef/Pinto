package Pinto::Action::Create;

# ABSTRACT: An action to create a new repository

use Moose;

use autodie;

use PerlIO::gzip;
use Path::Class;

extends 'Pinto::Action';

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

with qw(Pinto::Role::PathMaker);

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    my @created_files = ();

    # Create config dir
    my $config_dir = $self->config->config_dir();;
    $self->mkpath($config_dir);

    # Write config file
    my $config_file = $config_dir->file( $self->config->basename() );
    $self->config->write_config_file( file => $config_file );
    push @created_files, $config_file;

    $DB::single = 1;
    # Create modules dir
    my $modules_dir = $self->config->modules_dir();
    $self->mkpath($modules_dir);

    # Write module indexes
    push @created_files,
        $self->_write_modlist(),
          $self->idxmgr->master_index->write->file(),
            $self->idxmgr->local_index->write->file(),
              $self->idxmgr->mirror_index->write->file();

    # Create authors dir
    my $authors_dir = $self->config->authors_dir();
    $self->mkpath($authors_dir);

    # Write authors index
    push @created_files, $self->_write_mailrc();


    # Add new files to the store
    $self->store->add(file => $_) for @created_files;

    $self->add_message('Created a new Pinto repository');

    return 1;
}

#------------------------------------------------------------------------------


sub _write_modlist {
    my ($self) = @_;

    my $modlist_file = $self->config->modules_dir->file('03modlist.data.gz');
    open my $fh, '>:gzip', $modlist_file;
    print {$fh} $self->_modlist_data();
    close $fh;

    return $modlist_file;

}

#------------------------------------------------------------------------------

sub _write_mailrc {
    my ($self) = @_;

    my $mailrc_file = $self->config->authors_dir->file('01mailrc.txt.gz');
    open my $fh, '>:gzip', $mailrc_file;
    print {$fh} '';
    close $fh;

    return $mailrc_file;
}

#------------------------------------------------------------------------------

sub _modlist_data {

    return <<'END_MODLIST';
File:        03modlist.data
Description: These are the data that are published in the module
        list, but they may be more recent than the latest posted
        modulelist. Over time we'll make sure that these data
        can be used to print the whole part two of the
        modulelist. Currently this is not the case.
Modcount:    6137
Written-By:  PAUSE version 1.14
Date:        Thu, 25 Aug 2011 15:27:50 GMT

package CPAN::Modulelist;
# Usage: print Data::Dumper->new([CPAN::Modulelist->data])->Dump or similar
# cannot 'use strict', because we normally run under Safe
# use strict;
sub data {
my $result = {};
my $primary = "modid";
for (@$CPAN::Modulelist::data){
my %hash;
@hash{@$CPAN::Modulelist::cols} = @$_;
$result->{$hash{$primary}} = \%hash;
}
$result;
}
$CPAN::Modulelist::cols = [
'modid',
'statd',
'stats',
'statl',
'stati',
'statp',
'description',
'userid',
'chapterid'
];
$CPAN::Modulelist::data = [
];
END_MODLIST

}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#------------------------------------------------------------------------------

1;

__END__
