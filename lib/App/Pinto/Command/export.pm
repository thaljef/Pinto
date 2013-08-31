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
      [ 'notar|no-tar!' => 'do not check for system tar' ],
      [ 'output|o=s' => 'path to the exported directory/archive' ],
      [ 'output_format|output-format|F=s' => 'export format (dir/tar/zip)' ],
      [ 'prefix|p=s' => 'prefix to add to filenames in archive' ],
      [ 'stack|s=s' => 'stack/release to export' ],
      [ 'tar=s' => 'path to system tar to use' ],
    );
}

#------------------------------------------------------------------------------

sub validate_args {
    my ( $self, $opts, $args ) = @_;

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

  pinto --root=REPOSITORY_ROOT export [OPTIONS] [TARGETS]

=head1 DESCRIPTION

This command exports one stack in a directory or archive of your
choice, so that you can take it e.g. in locations where you don't have
a direct connection to the Internet. This allows you to pack all your
dependencies in a convenient place and be able to secure your installation
in the isolated server.

There are multiple different formats that you can export to:

=over

=item directory

the export is performed in a directory, so that you can choose to e.g.
test it locally before packing it

=item TAR archive

both in the compressed (gzip and bzip) and uncompressed variants. It tries
to use a system C<tar> if available, otherwise reverts to L<Archive::Tar>
(but note that this can be heavy on memory and computing, so system C<tar>
is preferable).

=item ZIP archive

which should be easier for distributing a stack to a Windows target

=item I<deployable> Perl program

which are true programs that will install the relevant modules when run

=back


=head1 TAR Archives

By default, the export subcommand tries to use system C<tar> if available,
reverting to L<Archive::Tar> otherwise (but note that this can be heavy
on memory and computing, so system C<tar> is preferable).

All compression types are supported if available in the tools, i.e. if
C<tar> supports them in the specific platform and/or the relevant perl
modules are installed.

=head2 Deployable Export

One interesting feature of the export subcommand is the possibility to
create a Perl program that will install the relevant modules when run.

It is actually a thin wrapper around cpanm, so the produced program can
be passed most of cpanm's command line options (e.g. C<-L> if you want
to install the modules in a directory of your choice). Of course it
sets cpanm's options C<--mirror> and C<--mirror-only> so that the
modules are actually taken from the exported repository that is
embedded in the Perl program itself.

When generating a deployable export, you can pass a list of modules
that will be installed when the generated program will be run. For
example, suppose you generate C<dep.pl> like this:

   pinto export -o dep.pl -F deployable.gz Module::First Module::Second

when you call it:

    dep.pl [OPTIONS]

it will be more or less equivalent to:

   echo Module::First Module::Second
   | cpanm --mirror-only --mirror /path/to/shipped/repository \
      [OPTIONS]


=head1 COMMAND ARGUMENTS

In the general case, the export subcommand ignores command arguments. They
are considered only when exporting to a deployable Perl script: in this
case, the list of command arguments is the list of modules that will be
installed by the resulting program.

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

=item deployable

generate a Perl program that can be deployed directly

=item deployable.bz2

same as deployable, but the data is compressed internally with bzip2
so that the resulting program is smaller

=item deployable.gz

same as deployable, but the data is compressed internally with gzip
so that the resulting program is smaller

=item directory

=item dir

generate a directory

=item tar

generate a TAR archive

=item tar.bz2

=item tbz

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

=item --stack=STACK

=item -s STACK

The stack to include in the export. If no STACK is provided, then
the default stack is exported.

In some future release it will also be possible to set a revision id
instead of a stack's name.

=back

=cut
