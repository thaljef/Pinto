package Pinto::Config;

# ABSTRACT: Internal configuration for a Pinto repository

use Moose;

use MooseX::Configuration;

use MooseX::Types::Moose qw(Str Bool Int);
use Pinto::Types qw(Dir File);
use URI;

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------
# Moose attributes

has root       => (
    is         => 'ro',
    isa        => Dir,
    required   => 1,
    coerce     => 1,
);


has root_dir   => (            # An alias for 'root'
    is         => 'ro',
    isa        => Dir,
    init_arg   => undef,
    default    => sub { return $_[0]->root() },
    lazy       => 1,
);


has authors_dir => (
    is        => 'ro',
    isa       => Dir,
    init_arg  => undef,
    default   => sub { return $_[0]->root_dir->subdir('authors') },
    lazy      => 1,
);


has modules_dir => (
    is        => 'ro',
    isa       => Dir,
    init_arg  => undef,
    default   => sub { return $_[0]->root_dir->subdir('modules') },
    lazy      => 1,
);


has index_file => (
    is        => 'ro',
    isa       => File,
    init_arg  => undef,
    default   => sub { return $_[0]->modules_dir->file('02packages.details.txt.gz') },
    lazy      => 1,
);


has mailrc_file => (
    is        => 'ro',
    isa       => File,
    init_arg  => undef,
    default   => sub { return $_[0]->authors_dir->file('01mailrc.txt.gz') },
    lazy      => 1,
);


has db_dir => (
    is        => 'ro',
    isa       => Dir,
    init_arg  => undef,
    default   => sub { return $_[0]->pinto_dir->subdir('db') },
    lazy      => 1,
);


has db_file => (
    is        => 'ro',
    isa       => File,
    init_arg  => undef,
    default   => sub { return $_[0]->db_dir->file('pinto.db') },
    lazy      => 1,
);


has pinto_dir => (
    is        => 'ro',
    isa       => Dir,
    init_arg  => undef,
    default   => sub { return $_[0]->root_dir->subdir('.pinto') },
    lazy      => 1,
);


has config_dir => (
    is        => 'ro',
    isa       => Dir,
    init_arg  => undef,
    default   => sub { return $_[0]->pinto_dir->subdir('config') },
    lazy      => 1,
);


has cache_dir => (
    is        => 'ro',
    isa       => Dir,
    init_arg  => undef,
    default   => sub { return $_[0]->pinto_dir->subdir('cache') },
    lazy      => 1,
);


has basename => (
    is        => 'ro',
    isa       => Str,
    init_arg  => undef,
    default   => 'pinto.ini',
);


has devel => (
    is        => 'ro',
    isa       => Bool,
    key       => 'devel',
    default   => 0,
    documentation => 'Include development releases in the index',
);


has noinit => (
    is       => 'ro',
    isa      => Bool,
    key      => 'noinit',
    default  => 0,
    documentation => 'Do not pull/update from VCS before each operation',
);


has sources  => (
    is        => 'ro',
    isa       => Str,
    key       => 'sources',
    default   => 'http://cpan.perl.org',
    documentation => 'URLs of repositories for foreign distributions (space delimited)',
);


has sources_list => (
    isa        => 'ArrayRef[URI]',
    builder    => '_build_sources_list',
    traits     => ['Array'],
    handles    => { sources_list => 'elements' },
    init_arg   => undef,
    lazy       => 1,
);


has store => (
    is        => 'ro',
    isa       => Str,
    key       => 'store',
    default   => 'Pinto::Store::File',
    documentation => 'Name of class that handles storage of your repository',
);

#------------------------------------------------------------------------------
# Builders

sub _build_config_file {
    my ($self) = @_;

    my $config_file = $self->config_dir->file( $self->basename() );

    return -e $config_file ? $config_file : ();
}

#------------------------------------------------------------------------------

sub _build_sources_list {
    my ($self) = @_;

    my @sources = split m{ \s+ }mx, $self->sources();
    my @source_urls = map { URI->new($_) } @sources;

    return \@source_urls;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#------------------------------------------------------------------------------

1;

__END__

=head1 DESCRIPTION

This is a private module for internal use only.  There is nothing for
you to see here (yet).

=cut
