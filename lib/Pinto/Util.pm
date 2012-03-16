package Pinto::Util;

# ABSTRACT: Static utility functions for Pinto

use strict;
use warnings;
use version;

use Carp;
use Try::Tiny;
use Path::Class;
use Readonly;

use Pinto::Exceptions qw(throw_version throw_error);

use namespace::autoclean;

#-------------------------------------------------------------------------------

# VERSION

#-------------------------------------------------------------------------------

Readonly my %VCS_FILES => (map {$_ => 1} qw(.svn .git .gitignore CVS));

#-------------------------------------------------------------------------------

=func author_dir( @base, $author )

Given the name of an C<$author>, returns the directory where the
distributions for that author belong (as a L<Path::Class::Dir>).  The
optional C<@base> can be a series of L<Path::Class:Dir> or path parts
(as strings).  If C<@base> is given, it will be prepended to the
directory that is returned.

=cut

sub author_dir {                                  ## no critic (ArgUnpacking)
    my $author = uc pop;
    my @base =  @_;

    return dir(@base, substr($author, 0, 1), substr($author, 0, 2), $author);
}

#-------------------------------------------------------------------------------

sub parse_dist_url {
    my ($url) = @_;

    #  $path = '/yadda/yadda/authors/id/A/AU/AUTHOR/Foo-1.2.tar.gz'
    my $path = $url->path();

    if ( $path =~ s{^ (.*) /authors/id/(.*) $}{$2}mx ) {

        # $path = 'A/AU/AUTHOR/Foo-1.2.tar.gz'
        my $source     = $url->isa('URI::file') ? $1 : $url->authority();
        my @path_parts = split m{ / }mx, $path; # qw( A AU AUTHOR Foo-1.2.tar.gz )
        my $author     = $path_parts[2];
        return ($source, $path, $author);
    }
    else {

        throw_error 'Unable to parse url: $url';
    }

}

#-------------------------------------------------------------------------------

=func is_vcs_file($path)

Given a path (which may be a file or directory), returns true if that path
is part of the internals of a version control system (e.g. Git, Subversion).

=cut

sub is_vcs_file {
    my ($file) = @_;

    $file = file($file) unless eval { $file->isa('Path::Class::File') };

    return exists $VCS_FILES{ $file->basename() };
}

#-------------------------------------------------------------------------------

sub isa_perl {
    my ($path_or_url) = @_;

    return $path_or_url =~ m{ / perl-[\d.]+ \.tar \.gz $ }mx;
}

#-------------------------------------------------------------------------------

sub mtime {
    my ($file) = @_;

    croak 'Must supply a file' if not $file;
    croak "$file does not exist" if not -e $file;

    return (stat $file)[9];
}

#-------------------------------------------------------------------------------

sub added_dist_message {
    my ($distribution) = @_;

    return _dist_message($distribution, 'Added');
}

#-------------------------------------------------------------------------------

sub removed_dist_message {
    my ($distribution) = @_;

    return _dist_message($distribution, 'Removed');
}

#-------------------------------------------------------------------------------

sub imported_dist_message {
    my ($distribution) = @_;

    return _dist_message($distribution, 'Imported');
}

#-------------------------------------------------------------------------------

sub imported_prereq_dist_message {
    my ($distribution) = @_;

    return _dist_message($distribution, 'Imported prerequisite');
}

#-------------------------------------------------------------------------------

sub _dist_message {
    my ($dist, $action) = @_;

    my $vnames = join "\n    ", sort map { $_->vname() } $dist->packages();

    return "$action distribution $dist providing:\n    $vnames";
}

#-------------------------------------------------------------------------------

sub args_from_fh {
    my ($fh) = @_;

    my @args;
    while (my $line = <$fh>) {
        chomp $line;
        next if not length $line;
        next if $line =~ m/^ \s* [;#]/x;
        next if $line !~ m/\S/x;
        push @args, $line;
    }

    return @args;
}

#-------------------------------------------------------------------------------
1;

__END__

=head1 DESCRIPTION

This is a private module for internal use only.  There is nothing for
you to see here (yet).

=cut
