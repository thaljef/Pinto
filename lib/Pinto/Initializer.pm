# ABSTRACT: Initializes a new Pinto repository

package Pinto::Initializer;

use Moose;
use MooseX::MarkAsMethods (autoclean => 1);

use IO::Zlib;
use Path::Class;

use Pinto;
use Pinto::Config;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

sub init {
    my ($self, %args) = @_;

    die "Must specify a root\n" 
        if not $args{root};

    $self->_check_sanity(%args);
    $self->_make_dirs(%args);
    $self->_write_config(%args);
    $self->_write_mailrc(%args);
    $self->_set_version(%args);
    $self->_create_db(%args);
    $self->_create_stack(%args);

    return $self;
}

#------------------------------------------------------------------------------

sub _check_sanity {
    my ($self, %args) = @_;

    my $root_dir = dir($args{root});
    die "Directory $root_dir must be empty to create a repository there\n"
        if -e $root_dir and $root_dir->children;

    return;
}

#------------------------------------------------------------------------------

sub _make_dirs {
    my ($self, %args) = @_;

    my $config = Pinto::Config->new(root => $args{root});

    for my $dir ( qw(root config cache log authors db) ) {
        my $method = "${dir}_dir";
        $config->$method->mkpath;
    }

    return;
}

#------------------------------------------------------------------------------

sub _write_config {
    my ($self, %args) = @_;

    my $config = Pinto::Config->new(root => $args{root});

    my $config_file = $config->config_dir->file( $config->basename );
    $config->write_config_file( file => $config_file, values => \%args );

    return;
};

#------------------------------------------------------------------------------

sub _write_mailrc {
    my ($self, %args) = @_;

    my $config = Pinto::Config->new(root => $args{root});

    my $fh = IO::Zlib->new($config->mailrc_file->stringify, 'wb') or die $!;
    print {$fh} ''; # File will be empty, but have gzip headers
    close $fh or throw $!;

    return;
}

#------------------------------------------------------------------------------


sub _set_version {
    my ($self, %args) = @_;

    my $pinto = Pinto->new(root => $args{root});

    $pinto->repo->set_version;

    return;
}

#------------------------------------------------------------------------------

sub _create_db {
    my ($self, %args) = @_;

    my $pinto = Pinto->new(root => $args{root});

    $pinto->repo->db->deploy;

    return;
}

#------------------------------------------------------------------------------

sub _create_stack {
    my ($self, %args) = @_;

    my $stack      = $args{stack} || 'master';
    my $is_default = $args{no_default} ? 0 : 1;
    my $pinto      = Pinto->new(root => $args{root});

    $pinto->run(New => (stack => $stack, default => $is_default));

    return;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------

1;

__END__
