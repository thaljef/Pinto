# ABSTRACT: Initializes a new Pinto repository

package Pinto::Initializer;

use Moose;
use MooseX::MarkAsMethods (autoclean => 1);

use PerlIO::gzip;

use Pinto;

use autodie;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

with qw( Pinto::Role::Configurable
         Pinto::Role::Loggable );

#------------------------------------------------------------------------------

# TODO: Can we use proper Moose attributes here, rather than passing a big
# hash of attributes to the init() method?  I seem to remember that I needed
# to do this so I would have something to give to $config->write.  But I'm
# not convinced this was the right solution.  It would probably be better
# to just put all the config attributes into repository props anyway.

#------------------------------------------------------------------------------


sub init {
    my ($self, %args) = @_;

    # Sanity checks
    my $root_dir = $self->config->root_dir;
    die "Directory $root_dir must be empty to create a repository there\n"
        if -e $root_dir and $root_dir->children;

    # Make directory structure
    for my $dir ( qw(root config cache log modules authors db vcs) ) {
        my $meth = "${dir}_dir";
        $self->config->$meth->mkpath;
    }


    # Write config file
    my $config_file = $self->config->config_dir->file( $self->config->basename );
    $self->config->write_config_file( file => $config_file, values => \%args );

    # Write modlist
    $self->_write_modlist;

    # Write authors index
    $self->_write_mailrc;

    # Establish version
    $self->_set_version;

    # Set up database
    $self->_create_db;

    # Set up version control
    $self->_create_vcs;

    # Create master stack
    $self->_create_stack(%args);

    # Log message for posterity
    $self->notice("Created new repository at $root_dir");

    return $self;
}

#------------------------------------------------------------------------------


sub _write_modlist {
    my ($self) = @_;

    my $modlist_file = $self->config->modlist_file;
    open my $fh, '>:gzip', $modlist_file;
    print {$fh} $self->_modlist_data();
    close $fh;

    return $modlist_file;

}

#------------------------------------------------------------------------------

sub _write_mailrc {
    my ($self) = @_;

    my $mailrc_file = $self->config->mailrc_file;
    open my $fh, '>:gzip', $mailrc_file;
    print {$fh} '';
    close $fh;

    return $mailrc_file;
}

#------------------------------------------------------------------------------

sub _modlist_data {

    my $template = <<'END_MODLIST';
File:        03modlist.data
Description: This a placeholder for CPAN.pm
Modcount:    0
Written-By:  Id: %s
Date:        %s

package %s;

sub data { {} }

1;
END_MODLIST

    # If we put "package CPAN::Modulelist" in the above string, it
    # fools the PAUSE indexer into thinking that we provide the
    # CPAN::Modulelist package.  But we don't.  To get around this,
    # I'm going to inject the string "CPAN::Modulelist" into the
    # template.

    return sprintf $template, $0, scalar localtime, 'CPAN::Modulelist';
}

#------------------------------------------------------------------------------

sub _set_version {
    my ($self) = @_;

    my $pinto = Pinto->new(root => $self->config->root);

    $pinto->repo->set_version;

    return;
}

#------------------------------------------------------------------------------

sub _create_db {
    my ($self) = @_;

    my $pinto = Pinto->new(root => $self->config->root);

    $pinto->repo->db->deploy;

    return;
}

#------------------------------------------------------------------------------

sub _create_vcs {
    my ($self) = @_;

    my $pinto = Pinto->new(root => $self->config->root);

    $pinto->repo->vcs->initialize;

    return;
}

#------------------------------------------------------------------------------

sub _create_stack {
    my ($self, %args) = @_;

    my $is_default = $args{nodefault} ? 0 : 1;
    my $pinto      = Pinto->new(root => $self->config->root);

    $pinto->run( New => (stack   => 'master',
                         default => $is_default) );
    
    return;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------

1;

__END__
