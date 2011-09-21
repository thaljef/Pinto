package Pinto::Util;

# ABSTRACT: Static utility functions for Pinto

use strict;
use warnings;
use version;

use Try::Tiny;
use Path::Class;
use Readonly;

use namespace::autoclean;

#-------------------------------------------------------------------------------

# VERSION

#-------------------------------------------------------------------------------

Readonly my %SCM_FILES => (map {$_ => 1} qw(.svn .git .gitignore CVS));

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

=func is_url($it)

Returns true if C<$it> is a L<URI> or looks like a URL.

=cut

sub is_url {
    my ($it) = @_;

    return 1 if eval { $it->isa('URI') };
    return 0 if eval { $it->isa('Path::Class::File') };
    return $it =~ m/^ (?: http|ftp|file) : /x;
}

#-------------------------------------------------------------------------------

=func is_source_control_file($path)

Given a path (which may be a file or directory), returns true if that path
is part of the internals of a version control system (e.g. Git, Subversion).

=cut

sub is_source_control_file {
    my ($file) = @_;

    return exists $SCM_FILES{$file};
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

sub _dist_message {
    my ($dist, $action) = @_;

    my @items = sort map { $_->name() . ' ' . $_->version() } $dist->packages();

    return "$action distribution $dist providing:\n    " . join "\n    ", @items;
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

sub numify_version {
    my ($version) = @_;

    my $numeric_version;
    try   { $numeric_version = version->parse($version)->numify() }
    catch { Pinto::Exception->throw($_) };

    return $numeric_version;
}

#-------------------------------------------------------------------------------
1;

__END__

=head1 DESCRIPTION

This is a private module for internal use only.  There is nothing for
you to see here (yet).

=cut
