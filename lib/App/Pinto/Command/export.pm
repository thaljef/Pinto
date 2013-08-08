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
      [ 'all|a!' => 'include all stacks in export' ],
      [ 'default|d!' => 'include default stack in export' ],
      [ 'output|o=s' => 'path to the exported directory/archive' ],
      [ 'of|output-format|F=s' => 'export format (dir/tar/zip)' ],
      [ 'prefix|p=s' => 'prefix to add to filenames in archive' ],
    );
}

#------------------------------------------------------------------------------

sub validate_args {
    my ( $self, $opts, $args ) = @_;

    # Compute and check target stacks
    my @stacks = $self->pinto->repo->get_all_stacks();
    my ($default_stack, %stack_for);
    for my $stack (@stacks) {
        $default_stack = "$stack" if $stack->is_default();
        $stack_for{$stack} = 1;
    }

    my $wants_default = delete($opts->{default}) || ! scalar(@{$args});
    my %wanted;
    if (my $wants_all = delete $opts->{all}) {
        %wanted = %stack_for;
    }
    else {
        %wanted = map {
            $_ => ($stack_for{$_} || die "inexistent stack '$_'\n")
        } (@{$args}, $wants_default ? $default_stack : ());
    }
    $opts->{default_stack} = $default_stack
        if exists $wanted{$default_stack};
    @{$args} = keys %wanted;

    # Normalize and check output-format
    my $of = delete $opts->{'of'};
    $of = 'dir' unless defined $of;
    $opts->{output_format} = {
        dir => 'directory',
        directory => 'directory',
        tar => 'tar',
        zip => 'zip',
    }->{lc($of)} or die "unrecognised output format '$of'\n";
    $of = $opts->{output_format};

    # Check output for non-existence
    my $o = $opts->{output};
    $o = 'pinto-export' unless defined $o;
    die "export file '$o' already exists\n" if -e $o;
    $opts->{output} = $o;

    return 1;
}

#------------------------------------------------------------------------------

sub args_attribute { return 'stack_names' }

#------------------------------------------------------------------------------

sub args_from_stdin { return 1 }

#------------------------------------------------------------------------------

1;

__END__

=pod

=head1 SYNOPSIS

  pinto --root=REPOSITORY_ROOT export [OPTIONS] TARGET ...

=head1 DESCRIPTION

This command exports one or more stacks in a directory or archive of your
choice, so that you can take it e.g. in locations where you don't have
a direct connection to the Internet. This allows you to pack all your
dependencies in a convenient place and be able to secure your installation
in the isolated server.

=head1 COMMAND ARGUMENTS

The list of stacks to include in the export. If no target is provided, then
the default stack is exported. If you want to export a list of stacks AND
the default stack, then use also option C<--default> described below.

=head1 COMMAND OPTIONS

=over 4

=item --all

=item -a

Include all stacks in the export.

=item --default

=item -d

Ensure that the default stack is included in the export.

The default stack is always included whenever the list of TARGETs is left
empty. If you want to provide a list of TARGETs and in addition ensure that
the default stack is included, use this option.

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
