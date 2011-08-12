package Pinto::Config;

# ABSTRACT: User configuration for Pinto

use Moose;
use MooseX::Configuration;
use MooseX::LazyRequire;

use MooseX::Types::Moose qw(Str Bool Int);
use Pinto::Types qw(AuthorID URI Dir);

use Carp;
use English qw(-no_match_vars);

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


has 'source'  => (
    is        => 'ro',
    isa       => URI,
    key       => 'source',
    default   => 'http://cpan.perl.org',
    coerce    => 1,
);


has 'author'  => (
    is        => 'ro',
    isa       => AuthorID,
    key       => 'author',
    coerce    => 1,
    lazy      => 1,
    builder   => '_build_author',
);


has 'nocleanup' => (
    is        => 'ro',
    isa       => Bool,
    key       => 'nocleanup',
    default   => 0,
);


has 'noinit' => (
    is        => 'ro',
    isa       => Bool,
    key       => 'noinit',
    default   => 0,
);


has 'force'    => (
    is        => 'ro',
    isa       => Bool,
    key       => 'force',
    default   => 0,
);


has 'store' => (
    is        => 'ro',
    isa       => Str,
    key       => 'store',
    default   => 'Pinto::Store',
);


has 'nocommit' => (
    is       => 'ro',
    isa      => Bool,
    key      => 'nocommit',
    default  => 0,
);


has 'notag' => (
    is      => 'ro',
    isa     => 'Bool',
    key     => 'notag',
    default => 0,
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
    is            => 'ro',
    isa           => Str,
    key           => 'trunk',
    section       => 'Pinto::Store::Svn',
    lazy_required => 1,
);


has 'svn_tag' => (
    is          => 'ro',
    isa         => Str,
    key         => 'tag',
    section     => 'Pinto::Store::Svn',
    default     => '',
);

#------------------------------------------------------------------------------
# Builders

sub _build_config_file {

    my $PINTO_ENV_VAR = $ENV{PERL_PINTO};
    return $PINTO_ENV_VAR if $PINTO_ENV_VAR and -e $PINTO_ENV_VAR;

    require File::HomeDir;
    my $home = File::HomeDir->my_home()
        or croak 'Unable to determine your home directory';

    require Path::Class;
    my $file = Path::Class::file($home, qw(.pinto config.ini));

    return -e $file ? $file : ();
}

#------------------------------------------------------------------------------

sub _build_author {

    # Look at typical environment variables
    for my $var ( qw(USERNAME USER LOGNAME) ) {
        return uc $ENV{$var} if $ENV{$var};
    }

    # Try using pwent.  Probably only works on *nix
    if (my $name = getpwuid($REAL_USER_ID)) {
        return uc $name;
    }

    # Otherwise, we are hosed!
    croak 'Unable to determine your user name';

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
