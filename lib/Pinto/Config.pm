package Pinto::Config;

# ABSTRACT: User configuration for Pinto

use Moose;
use MooseX::Configuration;

use MooseX::Types::Moose qw(Str Bool Int);
use MooseX::Types::Pinto qw(AuthorID URI Dir);

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------
# Moose attributes

has 'local'   => (
    is        => 'ro',
    isa       => Dir,
    key       => 'local',
    required  => 1,
    coerce    => 1,
);


has 'mirror'  => (
    is        => 'ro',
    isa       => URI,
    key       => 'mirror',
    default   => 'http://cpan.perl.org',
    coerce    => 1,
);


has 'author'  => (
    is        => 'ro',
    isa       => AuthorID,
    key       => 'author',
    coerce    => 1,
);


has 'nocleanup' => (
    is        => 'ro',
    isa       => Bool,
    key       => 'nocleanup',
    default   => 0,
);


has 'force'    => (
    is        => 'ro',
    isa       => Bool,
    key       => 'force',
    default   => 0,
);


has 'store_class' => (
    is        => 'ro',
    isa       => Str,
    key       => 'store_class',
    default   => 'Pinto::Store',
);

has 'nocommit' => (
    is       => 'ro',
    isa      => Bool,
    key      => 'nocommit',
    default  => 0,
);

has 'quiet'  => (
    is       => 'ro',
    isa      => Bool,
    key      => 'quiet',
    default  => 0,
);


has 'verbose' => (
    is          => 'ro',
    isa         => Int,
    key         => 'verbose',
    default     => 0,
);


has 'svn_trunk' => (
    is          => 'ro',
    isa         => Str,
    key         => 'trunk',
    section     => 'Pinto::Store::Svn',
);


has 'svn_tag' => (
    is          => 'ro',
    isa         => Str,
    key         => 'tag',
    section     => 'Pinto::Store::Svn',
);

#------------------------------------------------------------------------------
# Override builder

sub _build_config_file {

    require File::HomeDir;
    require Path::Class;

    # TODO: look at $ENV{PERL_PINTO} first.
    return Path::Class::file( File::HomeDir->my_home(), qw(.pinto config.ini) );
}

#------------------------------------------------------------------------------

__PACKAGE__->meta()->make_immutable();

#------------------------------------------------------------------------------

1;

__END__

=head1 DESCRIPTION

This is a private module for internal use only.  There is nothing for
you to see here (yet).

=cut
