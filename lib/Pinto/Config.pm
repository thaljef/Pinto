package Pinto::Config;

# ABSTRACT: Internal configuration for a Pinto repository

use Moose;

use MooseX::Configuration;

use MooseX::Types::Moose qw(Str Bool Int);
use Pinto::Types 0.017 qw(URI Dir);

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


has config_dir => (
    is        => 'ro',
    isa       => Dir,
    init_arg  => undef,
    default   => sub { return $_[0]->repos->subdir('config') },
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
    documentation => 'If true, then Pinto will not delete older distributions when newer versions are added',
);


has noclobber => (
    is        => 'ro',
    isa       => Bool,
    key       => 'noclobber',
    default   => 0,
    documentation => 'If true, then Pinto will not clobber existing packages when adding new ones',
);


has noinit => (
    is       => 'ro',
    isa      => Bool,
    key      => 'noinit',
    default  => 0,
    documentation => 'If true, then Pinto will not pull/update from VCS before each operation',
);


has source  => (
    is        => 'ro',
    isa       => URI,
    key       => 'source',
    default   => 'http://cpan.perl.org',
    coerce    => 1,
    documentation => 'URL of a CPAN mirror (or Pinto repository) where foreign dists will be pulled from',
);


has store => (
    is        => 'ro',
    isa       => Str,
    key       => 'store',
    default   => 'Pinto::Store',
    documentation => 'Name of the class that will handle storage of your repository',
);

# TODO: Consider moving VCS-related config to a separate Config class.

has svn_trunk => (
    is        => 'ro',
    isa       => Str,
    key       => 'trunk',
    section   => 'Pinto::Store::VCS::Svn',
);


has svn_tag => (
    is        => 'ro',
    isa       => Str,
    key       => 'tag',
    section   => 'Pinto::Store::VCS::Svn',
    default   => '',
);

#------------------------------------------------------------------------------
# Builders

sub _build_config_file {
    my ($self) = @_;

    my $config_file = $self->config_dir->file( $self->basename() );

    return -e $config_file ? $config_file : ();
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
