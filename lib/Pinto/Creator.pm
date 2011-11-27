package Pinto::Creator;

# ABSTRACT: Creates a new Pinto repository

use Moose;

use autodie;

use PerlIO::gzip;
use Path::Class;

use Pinto::Logger;
use Pinto::Config;
use Pinto::Database;

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

with qw( Pinto::Interface::Loggable
         Pinto::Interface::Configurable
         Pinto::Role::PathMaker );

#------------------------------------------------------------------------------
# Construction

sub BUILDARGS {
    my ($class, %args) = @_;

    $args{logger} ||= Pinto::Logger->new( %args );
    $args{config} ||= Pinto::Config->new( %args );

    return \%args;
}

#------------------------------------------------------------------------------

sub create {
    my ($self, %args) = @_;

    # Sanity checks
    my $root_dir = $self->config->root_dir();
    $self->fatal("Directory $root_dir is not empty")
        if -e $root_dir and $root_dir->children();

    # Create repos root directory
    $self->mkpath($root_dir)
        if not -e $root_dir;

    # Create config dir
    my $config_dir = $self->config->config_dir();
    $self->mkpath($config_dir);

    # Write config file
    my $config_file = $config_dir->file( $self->config->basename() );
    $self->config->write_config_file( file => $config_file, values => \%args );

    # Create modules dir
    my $modules_dir = $self->config->modules_dir();
    $self->mkpath($modules_dir);

   # Create cache dir
    my $cache_dir = $self->config->cache_dir();
    $self->mkpath($cache_dir);

    # Create database
    my $db = Pinto::Database->new( config => $self->config(),
                                   logger => $self->logger() );
    $db->deploy();

    # Write package index
    $db->write_index();

    # Write modlist
    $self->_write_modlist();

    # Create authors dir
    my $authors_dir = $self->config->authors_dir();
    $self->mkpath($authors_dir);

    # Write authors index
    $self->_write_mailrc();

    return $self;
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
