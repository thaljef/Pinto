package Pinto::Util;

# ABSTRACT: Static utility functions for Pinto

use strict;
use warnings;
use version;

use Carp;
use Try::Tiny;
use Path::Class;
use Digest::MD5;
use Digest::SHA;
use DateTime;
use Readonly;

use namespace::autoclean;

#-------------------------------------------------------------------------------

# VERSION

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

        confess 'Unable to parse url: $url';
    }

}

#-------------------------------------------------------------------------------

sub isa_perl {
    my ($path_or_url) = @_;

    return $path_or_url =~ m{ / perl-[\d.]+ \.tar \.gz $ }mx;
}

#-------------------------------------------------------------------------------

Readonly my %VCS_FILES => (map {$_ => 1} qw(.svn .git .gitignore CVS));

sub is_vcs_file {
    my ($file) = @_;

    $file = file($file) unless eval { $file->isa('Path::Class::File') };

    return exists $VCS_FILES{ $file->basename() };
}



#-------------------------------------------------------------------------------

sub mtime {
    my ($file) = @_;

    confess 'Must supply a file' if not $file;
    confess "$file does not exist" if not -e $file;

    return (stat $file)[9];
}

#-------------------------------------------------------------------------------

sub md5 {
    my ($file) = @_;

    confess 'Must supply a file' if not $file;
    confess "$file does not exist" if not -e $file;

    my $fh = $file->openr();
    my $md5 = Digest::MD5->new->addfile($fh)->hexdigest();

    return $md5;
}

#-------------------------------------------------------------------------------

sub sha256 {
    my ($file) = @_;

    confess 'Must supply a file' if not $file;
    confess "$file does not exist" if not -e $file;

    my $fh = $file->openr();
    my $sha256 = Digest::SHA->new(256)->addfile($fh)->hexdigest();

    return $sha256;
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

=func ls_time_format( $seconds_since_epoch )

Formats a time value into a string that is similar to what you see in
the output from the C<ls -l> command.  If the given time is less than
1 year ago from now, you'll see the month, day, and time.  If the time
is more than 1 year ago, you'll see the month, day, and year.

=cut


sub ls_time_format {
    my ($time) = @_;
    my $now = time;
    my $diff = $now - $time;
    my $one_year = 60 * 60 * 24 * 365;  # seconds per year

    my $format = $diff > $one_year ? '%b %e  %Y' : '%b %e %H:%M';
    return DateTime->from_epoch( time_zone => 'local', epoch => $time )->strftime($format);
}

#-------------------------------------------------------------------------------
1;

__END__

=head1 DESCRIPTION

This is a private module for internal use only.  There is nothing for
you to see here (yet).

=cut
