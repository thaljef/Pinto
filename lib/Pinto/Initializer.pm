# ABSTRACT: Initializes a new Pinto repository

package Pinto::Initializer;

use Moose;
use MooseX::MarkAsMethods (autoclean => 1);

use Pinto;
use Pinto::File::Mailrc;

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
    for my $dir ( qw(root config cache log authors db) ) {
        my $meth = "${dir}_dir";
        $self->config->$meth->mkpath;
    }

    # Write config file
    $self->_write_config(%args);

    # Write authors index
    $self->_write_mailrc;

    # Establish version
    $self->_set_version;

    # Set up database
    $self->_create_db;

    # Log message for posterity
    $self->notice("Created new repository at $root_dir");

    # Create initial stack
    $self->_create_stack(%args);

    return $self;
}

#------------------------------------------------------------------------------

sub _write_config {
    my ($self, %args) = @_;

    my $config_file = $self->config->config_dir->file( $self->config->basename );
    $self->config->write_config_file( file => $config_file, values => \%args );
};

#------------------------------------------------------------------------------

sub _write_mailrc {
    my ($self) = @_;

    my $pinto  = Pinto->new(root => $self->config->root);
    my $mailrc = Pinto::File::Mailrc->new(repo => $pinto->repo);
    $mailrc->write_mailrc;

    return;
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

sub _create_stack {
    my ($self, %args) = @_;

    my $stack      = $args{stack} || 'master';
    my $is_default = $args{no_default} ? 0 : 1;
    my $pinto      = Pinto->new(root => $self->config->root);

    $pinto->run( New => (stack   => $stack,
                         default => $is_default) );
    return;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------

1;

__END__
