# ABSTRACT: export stack(s) to directory or archive

package App::Pinto::Command::export;

use strict;
use warnings;

#-----------------------------------------------------------------------------

use base 'App::Pinto::Command';

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

sub opt_spec {
    my ( $self, $app ) = @_;

    return ( 
      [ 'output|o=s' => 'path to the exported directory/archive' ],
      [ 'output_format|output-format|F=s' => 'export format (dir/tar/zip)' ],
      [ 'prefix|p=s' => 'prefix to add to filenames in archive' ],
    );
}

#------------------------------------------------------------------------------

sub validate_args {
    my ( $self, $opts, $args ) = @_;

    # one optional STACK, defaults to the default stack
    $self->usage_error('Must specify at most one stack')
        if @{$args} > 1;
    $opts->{stack} = $args->[0] if @{$args};

    if (exists $opts->{output_format}) {
      my $of = lc(delete $opts->{output_format});
      $of = 'dir' if $of eq 'directory';
      $opts->{output_format} = $of;
    }

    return 1;
}

#------------------------------------------------------------------------------

sub args_from_stdin { return 1 }

#------------------------------------------------------------------------------

1;

__END__

=pod

=head1 SYNOPSIS

  pinto --root=REPOSITORY_ROOT export [OPTIONS] [STACK]

=head1 DESCRIPTION

This command exports one stack in a directory or archive of your
choice, so that you can take it e.g. in locations where you don't have
a direct connection to the Internet. This allows you to pack all your
dependencies in a convenient place and be able to secure your installation
in the isolated server.

=head1 COMMAND ARGUMENTS

The stack to include in the export. If no STACK is provided, then
the default stack is exported.

=head1 COMMAND OPTIONS

=over 4

=item --output=PATH

=item -o PATH

Set the path to the output of the extraction process. See also
C<--output-format> for setting the output format.

Must not already exist.

Defaults to C<pinto-export> in the current directory.

=item --output-format=FORMAT

=item -F FORMAT

Set the output format for the export. It can be one of the following:

=over 4

=item directory

=item dir

generate a directory

=item tar

generate a TAR archive

=item tar.bz2

generate a BZIP2 compressed TAR archive

=item tar.gz

=item tgz

generate a GZIP compressed TAR archive

=item zip

generate a ZIP archive

=back

By default, the directory format is assumed.

=item --prefix=PREFIX

=item -p PREFIX

Set a prefix to apply to all filenames when generating an archive. This
option is ignored when the output format is C<directory>.

Defaults to the empty string, i.e. no prefix is applied.

=back

=cut
