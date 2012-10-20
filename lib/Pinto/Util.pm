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
use Scalar::Util;
use DateTime;
use Readonly;

use Pinto::Constants qw($PINTO_STACK_NAME_REGEX $PINTO_PROPERTY_NAME_REGEX);
use Pinto::Exception qw(throw);

use namespace::autoclean;

use base qw(Exporter);

#-------------------------------------------------------------------------------

# VERSION

#-------------------------------------------------------------------------------

our @EXPORT_OK = qw(itis mtime);

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

sub itis {
    my ($var, $class) = @_;

    return ref $var && Scalar::Util::blessed($var) && $var->isa($class);
}

#-------------------------------------------------------------------------------

sub parse_dist_path {
    my ($path) = @_;

    # /yadda/authors/id/A/AU/AUTHOR/subdir1/subdir2/Foo-1.0.tar.gz

    if ( $path =~ s{^ (.*) /authors/id/(.*) $}{$2}mx ) {

        # $path = 'A/AU/AUTHOR/subdir/Foo-1.2.tar.gz'
        my @path_parts = split m{ / }mx, $path;
        my $author  = $path_parts[2];  # AUTHOR
        my $archive = $path_parts[-1]; # Foo-1.0.tar.gz
        return ($author, $archive);
    }
    else {

        confess 'Unable to parse url: $url';
    }

}

#-------------------------------------------------------------------------------

sub isa_perl {
    my ($path_or_url) = @_;

    return $path_or_url =~ m{ / perl-[\d.]+ \.tar \.(?: gz|bz2 ) $ }mx;
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

=func validate_property_name( $prop_name )

Throws an exception if the property name is invalid.  Currently, property names 
must be alphanumeric plus any underscores or hyphens.

=cut

sub validate_property_name {
    my ($prop_name) = @_;

    throw "Invalid property name $prop_name" if $prop_name !~ $PINTO_PROPERTY_NAME_REGEX;

    return $prop_name;
}

#-------------------------------------------------------------------------------

=func validate_stack_name( $stack_name )

Throws an exception if the stack name is invalid.  Currently, stack names must 
be alphanumeric plus underscores or hyphens.

=cut

sub validate_stack_name {
    my ($stack_name) = @_;

    throw "Invalid stack name $stack_name" if $stack_name !~ $PINTO_STACK_NAME_REGEX;

    return $stack_name;
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
