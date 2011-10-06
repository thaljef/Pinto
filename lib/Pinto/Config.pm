package Pinto::Config;

# ABSTRACT: Internal configuration for a Pinto repository

use Moose;

use MooseX::Configuration;

use MooseX::Types::Moose qw(Str Bool Int);
use Pinto::Types 0.017 qw(URI Dir File);
use URI;

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------
# Moose attributes

has repos   => (
    is        => 'ro',
    isa       => Dir,
    required  => 1,
    coerce    => 1,
);


has authors_dir => (
    is        => 'ro',
    isa       => Dir,
    init_arg  => undef,
    default   => sub { return $_[0]->repos->subdir('authors') },
    lazy      => 1,
);


has modules_dir => (
    is        => 'ro',
    isa       => Dir,
    init_arg  => undef,
    default   => sub { return $_[0]->repos->subdir('modules') },
    lazy      => 1,
);


has packages_details_file => (
    is        => 'ro',
    isa       => File,
    init_arg  => undef,
    default   => sub { return $_[0]->modules_dir->file('02packages.details.txt.gz') },
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
    default   => sub { return $_[0]->repos->subdir('.pinto') },
    lazy      => 1,
);


has config_dir => (
    is        => 'ro',
    isa       => Dir,
    init_arg  => undef,
    default   => sub { return $_[0]->pinto_dir->subdir('config') },
    lazy      => 1,
);


has basename => (
    is        => 'ro',
    isa       => Str,
    init_arg  => undef,
    default   => 'pinto.ini',
);


has nocleanup => (
    is        => 'ro',
    isa       => Bool,
    key       => 'nocleanup',
    default   => 0,
    documentation => 'Do not delete distributions when they become outdated',
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
    isa       => URI,
    key       => 'sources',
    default   => 'http://cpan.perl.org',
    coerce    => 1,
    documentation => 'URLs of repositories for foreign distributions (space delimited)',
);


has sources_list => (
    is         => 'ro',
    isa        => 'ArrayRef[URI]',
    builder    => '_build_sources_list',
    auto_deref => 1,
    init_arg   => undef,
    lazy       => 1,
);


has store => (
    is        => 'ro',
    isa       => Str,
    key       => 'store',
    default   => 'Pinto::Store',
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

    my @sources = split m{\s+}mx, $self->source();
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
