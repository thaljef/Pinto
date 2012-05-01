package App::Pinto::Admin::Command::create;

# ABSTRACT: create a new empty repository

use strict;
use warnings;

use Pinto::Creator;

#-----------------------------------------------------------------------------

use base 'App::Pinto::Admin::Command';

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

sub command_names { return qw( create new ) }

#------------------------------------------------------------------------------

sub opt_spec {
    my ($self, $app) = @_;

    return (
        [ 'devel'       => 'Include development releases in the repository index' ],
        [ 'log_level=s' => 'Minimum logging level for the repository log file'    ],
        [ 'source=s@'   => 'URL of upstream repository (repeatable)' ],
    );
}

#------------------------------------------------------------------------------

sub execute {
    my ($self, $opts, $args) = @_;

    my $global_opts = $self->app->global_options();

    $global_opts->{root}
        or die 'Must specify a repository root directory';    ## no critic qw(Carp)

    # Combine repeatable "source" options into one space-delimited "sources" option.
    # TODO: Use a config file format that allows multiple values per key (MVP perhaps?).
    $opts->{sources} = join ' ', @{ delete $opts->{source} } if defined $opts->{source};

    my $creator = Pinto::Creator->new( %{ $global_opts } );
    $creator->create( %{$opts} );
    return 0;
}

#------------------------------------------------------------------------------

1;

__END__

=pod

=head1 SYNOPSIS

  pinto-admin --root=/some/dir create [OPTIONS]

=head1 DESCRIPTION

This command creates a new, empty repository.  If the target directory
does not exist, it will be created for you.  If it does already exist,
then it must be empty.  The new repository will contain an empty (but
valid) index file.  You can set the configuration parameters of the
new repository using the command line options listed below.

=head1 COMMAND ARGUMENTS

None.

=head1 COMMAND OPTIONS

=over 4

=item --source URL

The URL of a repository where foreign distributions will be pulled
from.  This is usually the URL of a CPAN mirror, and it defaults to
L<http://cpan.perl.org>.  But it could also be a L<CPAN::Mini> mirror,
or another L<Pinto> repository.

You can specify multiple repository URLs by repeating the C<--source>
option.  Repositories that appear earlier in the list have priority
over those that appear later.  See L<Pinto::Manual> for more
information about using multiple source repositories.

=back

=cut
