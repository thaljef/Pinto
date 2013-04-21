# ABSTRACT: Static utility functions for Pinto

package Pinto::Util;

use strict;
use warnings;
use version;
use base qw(Exporter);

use Carp;
use DateTime;
use Path::Class;
use Digest::MD5;
use Digest::SHA;
use Scalar::Util;
use UUID::Tiny;
use IO::Interactive;
use Readonly;

use Pinto::Globals;
use Pinto::Constants qw(:all);

#-------------------------------------------------------------------------------

# VERSION

#-------------------------------------------------------------------------------

Readonly our @EXPORT_OK => qw(
    author_dir
    body_text
    current_author_id
    current_utc_time
    current_time_offset
    current_username
    debug
    decamelize
    indent_text
    interpolate
    is_blank
    is_not_blank
    is_interactive
    is_system_prop
    isa_perl
    itis
    md5
    mksymlink
    mtime
    parse_dist_path
    sha256
    title_text
    throw
    trim_text
    truncate_text
    user_colors
    uuid
    whine
);

Readonly our %EXPORT_TAGS => ( all => \@EXPORT_OK );

#-------------------------------------------------------------------------------

=func throw($message)

=func throw($exception_object)

Throws a L<Pinto::Exception> with the given message.  If given a reference
to a L<Pinto::Exception> object, then it just throws it again.

=cut

sub throw {
    my ($error) = @_;

    # Rethrowing...
    die $error if itis($error, 'Pinto::Exception');  ## no critic (Carping)

    require Pinto::Exception;
    Pinto::Exception->throw(message => "$error");

    return; # Should never get here
}

#-------------------------------------------------------------------------------

=func debug( $message )

=func debug( sub {...} )

Writes the message on STDERR if the C<PINTO_DEBUG> environment variable is true.
If the argument is a subroutine, it will be invoked and its output will be
written instead.  Always returns true.

=cut

sub debug {
    my ($it) = @_;

    # TODO: Use Carp instead?

    return 1 if not $ENV{PINTO_DEBUG};

    $it = $it->() if ref $it eq 'CODE';
    my ($file, $line) = (caller)[1,2];
    print { *STDERR } "$it in $file at line $line\n";

    return 1;
}

#-------------------------------------------------------------------------------

=func whine( $message )

Just calls warn(), but always appends the newline so that line numbers are
suppressed.

=cut

sub whine {
    my ($message) = @_;

    if ($ENV{DEBUG}) {
        Carp::cluck($message);
        return 1;
    }

    chomp $message;
    warn $message . "\n";

    return 1;
}

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

=func itis( $var, $class )

Asserts whether var is a blessed reference and is an instance of the
C<$class>.

=cut

sub itis {
    my ($var, $class) = @_;

    return ref $var && Scalar::Util::blessed($var) && $var->isa($class);
}

#-------------------------------------------------------------------------------

=func parse_dist_path( $path )

Parses a path like the ones you would see in a full URL to a
distribution in a CPAN repository, or the URL fragment you would see
in a CPAN index.  Returns the author and file name of the
distribution.  Subdirectories between the author name and the file
name are discarded.

=cut

sub parse_dist_path {
    my ($path) = @_;

    # eg: /yadda/authors/id/A/AU/AUTHOR/subdir1/subdir2/Foo-1.0.tar.gz
    # or: A/AU/AUTHOR/subdir/Foo-1.0.tar.gz

    if ( $path =~ s{^ (?:.*/authors/id/)? (.*) $}{$1}mx ) {

        # $path = 'A/AU/AUTHOR/subdir/Foo-1.0.tar.gz'
        my @path_parts = split m{ / }mx, $path;
        my $author  = $path_parts[2];  # AUTHOR
        my $archive = $path_parts[-1]; # Foo-1.0.tar.gz
        return ($author, $archive);
    }

    throw "Unable to parse path: $path";
}

#-------------------------------------------------------------------------------

=func isa_perl( $path_or_url )

Return true if C<$path_or_url> appears to point to a release of perl
itself.  This is based on some file naming patterns that I've seen in
the wild.  It may not be completely accurate.

=cut

sub isa_perl {
    my ($path_or_url) = @_;

    return $path_or_url =~ m{ / perl-[\d.]+ \.tar \.(?: gz|bz2 ) $ }mx;
}

#-------------------------------------------------------------------------------

=func mtime( $file )

Returns the last modification time (in epoch seconds) for the C<file>.
The argument is required and the file must exist or an exception will
be thrown.

=cut

sub mtime {
    my ($file) = @_;

    throw 'Must supply a file' if not $file;
    throw "$file does not exist" if not -e $file;

    return (stat $file)[9];
}

#-------------------------------------------------------------------------------

=func md5( $file )

Returns the C<MD-5> digest (as a hex string) for the C<$file>.  The
argument is required and the file must exist on an exception will be
thrown.

=cut

sub md5 {
    my ($file) = @_;

    throw 'Must supply a file' if not $file;
    throw "$file does not exist" if not -e $file;

    my $fh = $file->openr();
    my $md5 = Digest::MD5->new->addfile($fh)->hexdigest();

    return $md5;
}

#-------------------------------------------------------------------------------

=func sha256( $file )

Returns the C<SHA-256> digest (as a hex string) for the C<$file>.  The
argument is required and the file must exist on an exception will be
thrown.

=cut

sub sha256 {
    my ($file) = @_;

    throw 'Must supply a file' if not $file;
    throw "$file does not exist" if not -e $file;

    my $fh = $file->openr();
    my $sha256 = Digest::SHA->new(256)->addfile($fh)->hexdigest();

    return $sha256;
}

#-------------------------------------------------------------------------------

=func validate_property_name( $prop_name )

Throws an exception if the property name is invalid.  Currently,
property names must be alphanumeric plus any underscores or hyphens.

=cut

sub validate_property_name {
    my ($prop_name) = @_;

    throw "Invalid property name $prop_name" if $prop_name !~ $PINTO_PROPERTY_NAME_REGEX;

    return $prop_name;
}

#-------------------------------------------------------------------------------

=func validate_stack_name( $stack_name )

Throws an exception if the stack name is invalid.  Currently, stack
names must be alphanumeric plus underscores or hyphens.

=cut

sub validate_stack_name {
    my ($stack_name) = @_;

    throw "Invalid stack name $stack_name" if $stack_name !~ $PINTO_STACK_NAME_REGEX;

    return $stack_name;
}

#-------------------------------------------------------------------------------

=func current_utc_time()

Returns the current time (in epoch seconds) unless the current time has been
overridden by C<$Pinto::Globals::current_utc_time>.

=cut

sub current_utc_time {

    ## no critic qw(PackageVars)
    return $Pinto::Globals::current_utc_time
      if defined $Pinto::Globals::current_utc_time;

    return time;
}

#-------------------------------------------------------------------------------

=func current_time_offset()

Returns the offset between current UTC time and the local time in
seconds, unless overridden by C<$Pinto::Globals::current_time_offset>.
The C<current_time> function is used to determine the current UTC
time.

=cut

sub current_time_offset {

    ## no critic qw(PackageVars)
    return $Pinto::Globals::current_time_offset
      if defined $Pinto::Globals::current_time_offset;

    my $now    = current_utc_time;
    my $time   = DateTime->from_epoch(epoch => $now, time_zone => 'local');

    return $time->offset;
}

#-------------------------------------------------------------------------------

=func current_username()

Returns the username of the current user unless it has been overridden by
C<$Pinto::Globals::current_username>.  The username can be defined through
a number of environment variables.  Throws an exception if no username
can be determined.

=cut

sub current_username {

    ## no critic qw(PackageVars)
    return $Pinto::Globals::current_username
      if defined $Pinto::Globals::current_username;

    my $username =  $ENV{PINTO_USERNAME} || $ENV{USER} || $ENV{LOGIN} || $ENV{USERNAME} || $ENV{LOGNAME};

    throw "Unable to determine your username.  Set PINTO_USERNAME." if not $username;

    return $username
}

#-------------------------------------------------------------------------------

=func current_author_id()

Returns the author id of the current user unless it has been overridden by
C<$Pinto::Globals::current_author_id>.  The author id can be defined through
environment variables.  Otherwise it defaults to the upper-case form of the
C<current_username>.

=cut

sub current_author_id {

    ## no critic qw(PackageVars)
    return $Pinto::Globals::current_author_id
      if defined $Pinto::Globals::current_author_id;

    my $author_id =  $ENV{PINTO_AUTHOR_ID} || uc current_username;

    return $author_id;
}

#-------------------------------------------------------------------------------

=func is_interactive()

Returns true if the process is connected to an interactive terminal
(i.e.  a keyboard & screen) unless it has been overridden by
C<$Pinto::Globals::is_interactive>.

=cut

sub is_interactive {

    ## no critic qw(PackageVars)
    return $Pinto::Globals::is_interactive
      if defined $Pinto::Globals::is_interactive;

    return IO::Interactive::is_interactive;
}

#-------------------------------------------------------------------------------

=func interpolate($string)

Performs interpolation on a literal string.  The string should not
include anything that looks like a variable.  Only metacharacters
(like \n) will be interpolated correctly.

=cut

sub interpolate {
    my $string = shift;

    return eval qq{"$string"};  ## no critic qw(Eval)
}

#-------------------------------------------------------------------------------

=func trim_text($string)

Returns the string with all leading and trailing whitespace removed.

=cut

sub trim_text {
    my $string = shift;

    $string =~ s/^ \s+  //x;
    $string =~ s/  \s+ $//x;

    return $string;
}

#-------------------------------------------------------------------------------

=func title_text($string)

Returns all the characters in C<$string> before the first newline.  If
there is no newline, returns the entire C<$string>.

=cut

sub title_text {
    my $string = shift;

    my $nl = index $string, "\n";
    return $nl < 0 ? $string : substr $string, 0, $nl;
}

#-------------------------------------------------------------------------------

=func body_text($string)

Returns all the characters in C<$string> after the first newline.  If
there is no newline, returns an empty string.

=cut

sub body_text {
    my $string = shift;

    my $nl = index $string, "\n";
    return '' if $nl < 0 or $nl == length $string;
    return substr $string, $nl + 1;
}

#-------------------------------------------------------------------------------

=func truncate_text($string, $length, $elipses)

Truncates the C<$string> and appends C<$elipses> if the C<$string> is 
longer than C<$length> characters.  C<$elipses> defaults to '...' if 
not specified.

=cut

sub truncate_text {
    my ($string, $max_length, $elipses) = @_;

    return $string if not $max_length;
    return $string if length $string <= $max_length;

    $elipses = '...' if not defined $elipses;

    my $truncated = substr $string, 0, $max_length;

    return $truncated . $elipses;
}

#-------------------------------------------------------------------------------

=func decamelize($string)

Returns the string forced to lower case and words separated by underscores.
For example C<FooBar> becomes C<foo_bar>.

=cut

sub decamelize {
    my $string = shift;

    return if not defined $string;

    $string =~ s/ ([a-z]) ([A-Z]) /$1_$2/xg;

    return lc $string;
}


#-------------------------------------------------------------------------------

=func indent_text($string, $n)

Returns a copy of C<$string> with each line indented by C<$n> spaces.
In other words, it puts C<4n> spaces immediately after each newline
in C<$string>.  The original C<$string> is not modified.

=cut

sub indent_text {
    my ($string, $spaces) = @_;

    return $string if not $spaces;
    return $string if not $string;

    my $indent = ' ' x $spaces;
    $string =~ s/^ /$indent/xmg;

    return $string;
}

#-------------------------------------------------------------------------------

=func mksymlink($from => $to)

Creates a symlink between the two files.  No checks are performed to see
if either path is valid or already exists.  Throws an exception if the
operation fails or is not supported.

=cut

sub mksymlink {
    my ($from, $to) = @_;

    # TODO: Try to add Win32 support here, somehow.
    debug "Linking $to to $from";
    symlink $to, $from or throw "symlink to $to from $from failed: $!";

    return 1;
}

#-------------------------------------------------------------------------------

=func is_system_prop($string)

Returns true if C<$string> is the name of a system property.

=cut

sub is_system_prop {
    my $string = shift;

    return 0 if not $string;
    return $string =~ m/^ pinto- /x;
}

#-------------------------------------------------------------------------------

=func uuid()

Returns a UUID as a string.  Currently, the UUID is derived from
random numbers.

=cut

sub uuid {
  return UUID::Tiny::create_uuid_as_string( UUID::Tiny::UUID_V4 );
}


#-------------------------------------------------------------------------------

=func user_colors()

Returns a reference to an array containing the names of the colors pinto 
can use.  This can be influenced by setting the C<PINTO_COLORS> or 
C<PINTO_COLOURS> environment variables.

=cut

sub user_colors {
    my $colors = $ENV{PINTO_COLORS} || $ENV{PINTO_COLOURS};

    return $PINTO_DEFAULT_COLORS if not $colors;

    return [ split m/\s* , \s*/x, $colors ];
}

#-------------------------------------------------------------------------------

=func is_blank($string)

Returns true if the string is undefined, empty, or contains only whitespace.

=cut

sub is_blank {
    my ($string) = @_;

    return 1 if not $string;
    return 0 if $string =~ m/ \S /x;
    return 1;
}

#-------------------------------------------------------------------------------

=func is_not_blank($string)

Returns true if the string contains any non-whitespace characters.

=cut

sub is_not_blank {
    my ($string) = @_;

    return ! is_blank($string);
}

#-------------------------------------------------------------------------------
1;

__END__


=head1 DESCRIPTION

This is a private module for internal use only.  There is nothing for
you to see here (yet).  All API documentation is purely for my own
reference.

=cut
