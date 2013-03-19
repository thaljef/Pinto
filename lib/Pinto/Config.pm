# ABSTRACT: Internal configuration for a Pinto repository

package Pinto::Config;

use Moose;
use MooseX::Types::Moose qw(Str Bool Int ArrayRef);
use MooseX::MarkAsMethods (autoclean => 1);
use MooseX::Configuration;
use MooseX::Aliases;

use URI;
use English qw(-no_match_vars);

use Pinto::Types qw(Dir File Username Version);
use Pinto::Util qw(current_username current_time_offset);

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------
# Moose attributes

has root       => (
    is         => 'ro',
    isa        => Dir,
    alias      => 'root_dir',
    required   => 1,
    coerce     => 1,
);


has username  => (
    is        => 'ro',
    isa       => Username,
    default   => sub { return current_username },
    lazy      => 1,
);


has time_offset  => (
    is        => 'ro',
    isa       => Int,
    default   => sub { return current_time_offset },
    lazy      => 1,
);


has stacks_dir => (
    is        => 'ro',
    isa       => Dir,
    init_arg  => undef,
    default   => sub { return $_[0]->root_dir->subdir('stacks') },
    lazy      => 1,
);


has authors_dir => (
    is        => 'ro',
    isa       => Dir,
    init_arg  => undef,
    default   => sub { return $_[0]->root_dir->subdir('authors') },
    lazy      => 1,
);


has authors_id_dir => (
    is        => 'ro',
    isa       => Dir,
    init_arg  => undef,
    default   => sub { return $_[0]->authors_dir->subdir('id') },
    lazy      => 1,
);


has modules_dir => (
    is        => 'ro',
    isa       => Dir,
    init_arg  => undef,
    default   => sub { return $_[0]->root_dir->subdir('modules') },
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


has no_history => (
    is         => 'ro',
    isa        => Bool,
    key        => 'no_history',
    default    => 0,
    documentation => 'Do not keep stack snapshots at each revision',
);


has sources  => (
    is        => 'ro',
    isa       => Str,
    key       => 'sources',
    default   => 'http://cpan.perl.org http://backpan.perl.org',
    documentation => 'URLs of upstream repositories (space delimited)',
);


has sources_list => (
    isa        => ArrayRef['URI'],
    builder    => '_build_sources_list',
    traits     => ['Array'],
    handles    => { sources_list => 'elements' },
    init_arg   => undef,
    lazy       => 1,
);


has target_perl_version => (
    is        => 'ro',
    isa       => Version,
    default   => sub { $PERL_VERSION },
    coerce    => 1,
);


has version_file => (
    is           => 'ro',
    isa          => File,
    init_arg     => undef,
    default      => sub { return $_[0]->pinto_dir->file('version') },
    lazy         => 1,
);


has basename => (
    is        => 'ro',
    isa       => Str,
    init_arg  => undef,
    default   => 'pinto.ini',
);

#------------------------------------------------------------------------------

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

sub directories {
    my ($self) = @_;

    return ( 
        $self->root_dir,
        $self->config_dir,
        $self->cache_dir,
        $self->authors_dir,
        $self->db_dir
    );
}
#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------

1;

__END__

=head1 DESCRIPTION

This is a private module for internal use only.  There is nothing for
you to see here (yet).

=cut
