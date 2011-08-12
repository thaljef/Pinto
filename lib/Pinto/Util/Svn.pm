package Pinto::Util::Svn;

# ABSTRACT: Utility functions for working with Subversion

use strict;
use warnings;

use Carp qw(carp croak);
use IPC::Cmd 0.72 qw(run);
use List::MoreUtils qw(firstidx);
use Path::Class;

#--------------------------------------------------------------------------

# VERSION

#--------------------------------------------------------------------------

=func svn_mkdir(url => 'http://somewhere')

Given a URL that is presumed to be a location within a Subversion
repsitory, creates a directory at that location.  Any intervening
directories will be created for you.  If the direcory already exists,
an exception will be thrown.

=cut

sub svn_mkdir {
    my %args = @_;
    my $url = $args{url};
    my $dir = $args{dir};
    my $message = $args{message} || 'NO MESSAGE GIVEN';

    if ( $url and not svn_ls(url => $url) ) {
        return _svn( command => [qw(mkdir --parents -m), $message, $url]);
    }
    elsif ($dir and not -e $dir) {
        return _svn( command => [qw(mkdir --parents), $dir] );
    }

    return 1;
}

#--------------------------------------------------------------------------

=func svn_ls(url => 'http://somewhere')

Given a URL that is presumed to be a location within a Subversion
repository, returns true if that location actually exists.

=cut

sub svn_ls {
    my %args = @_;
    my $url  = $args{url};

    return _svn( command => ['ls', $url], croak => 0 );
}

#--------------------------------------------------------------------------

=func svn_checkout(url => 'http://somewhere' to => '/some/path')

Checks out the specified URL to the specified path.  If the URL does
not exist in the repository, it will be created for you.  If the path
already exists and it is a working copy for URL, an update will be
performed instead.

=cut

sub svn_checkout {
    my %args = @_;
    my $url  = $args{url};
    my $to   = $args{to};

    return _svn( command => ['co', $url, $to] )
        if not -e $to and svn_mkdir(url => $url);

    croak "$to already exists but is not an svn working copy. ",
        "Perhaps you should delete $to first or use a different directory"
            if not _is_svn_working_copy(directory => $to);

    my $wc_url = _url_for_wc_path(path => $to);

    croak "$to should be a working copy of $url but is actually of $wc_url"
            if $url ne $wc_url;

    return _svn( command => ['up', $to] );
}

#--------------------------------------------------------------------------

=func svn_schedule(path => '/some/path')

Given a path to a directory or file within a Subversion working copy,
recursively scans the directory for new or missing files and schedules
them or addition or deletion from the repository.  Any new file is
added, and any missing file is deleted.

=cut

sub svn_schedule {
    my %args = @_;
    my $starting_path = $args{path};

    my $buffer = '';
    _svn(command => ['status', $starting_path], buffer => \$buffer);

    for my $line (split /\n/, $buffer) {

        $line =~ /^(\S)\s+(\S+)$/
            or croak "Unable to parse svn status: $line";

        my ($status, $path) = ($1, $2);

        if ($status eq '?') {
            svn_add(path => $path);
        }
        elsif ($status eq '!') {
            svn_delete(path => $path, prune => 1);
        }
        elsif ($status =~ /^[AMD]$/) {
            # Do nothing!
        }
        else {
            # TODO: Decide how to handle other statuses (e.g. locked).
            carp "Unexpected status: $status for file $path";
        }
    }

    return 1;
}

#--------------------------------------------------------------------------

=func svn_add(path => '/some/path')

Schedules the specified path for addition to the repository.

=cut

sub svn_add {
    my %args = @_;
    my $path = $args{path};

    return _svn( command => ['add', $path] );
}

#--------------------------------------------------------------------------

=func svn_remove(path => '/some/path' prune => 1)

Schedules the specified path for remove from the repository.  If the
C<prune> flag is true, then any ancestors of the path will also be
removed if all their contents are scheduled for removal.

=cut

sub svn_remove {
    my %args  = @_;

    my $path  = $args{file};
    my $prune = $args{prune};

    return if not -e $path;
    croak "$path is not a file" if $path->is_dir();

    _svn( command => ['rm', '--force', $path] );

    if($prune) {
        while (my $dir = $path->parent() ) {
            last if not _all_scheduled_for_deletion(directory => $dir);
            _svn( command => ['rm', '--force', $dir] );
            $path = $dir;
        }
    }

    return $path;
}

#--------------------------------------------------------------------------

=func svn_commit(paths => [@paths], message => 'Commit message')

Commits all the changes to the specified C<@paths>.

=cut

sub svn_commit {
    my %args     = @_;
    my $paths    = $args{paths};
    my $message  = $args{message} || 'NO MESSAGE GIVEN';

    my @paths = ref $paths eq 'ARRAY' ? @{ $paths } : ($paths);
    return _svn(command => [qw(commit -m), $message, @paths] );
}

#--------------------------------------------------------------------------

=func svn_tag(from => 'http://here', to => 'http://there')

Creates a tag by copying from one URL to another.  Note this is a
server-side copy and does no affect on any working copy.

=cut

sub svn_tag {
    my %args = @_;
    my $from    = $args{from};
    my $to      = $args{to};
    my $message = $args{message} || 'NO MESSAGE GIVEN';

    return _svn(command => [qw(cp --parents -m), $message, $from, $to]);
}

#--------------------------------------------------------------------------

sub _url_for_wc_path {
    my %args = @_;
    my $path = $args{path};

    my $buffer = '';
    _svn( command => ['info', $path], buffer => \$buffer);

    $buffer =~ /^URL:\s+(\S+)$/m
        or croak "Unable to parse svn info: $buffer";

    return $1;
}

#--------------------------------------------------------------------------

sub _is_svn_working_copy {
    my %args = @_;
    my $directory = $args{directory};

    return -e dir($directory, '.svn');
}

#--------------------------------------------------------------------------

sub _all_scheduled_for_deletion {
    my %args      = @_;
    my $directory = dir($args{directory});

    for my $child ($directory->children()) {
        next if $child->basename() eq '.svn';
        _svn(command => ['status', $child], buffer => \my $buffer);
        return 0 if not $buffer or $buffer =~ m/^[^D]/m;
    }

    return 1;
}

#--------------------------------------------------------------------------

sub _svn {
    my %args = @_;
    my $command = $args{command};
    my $buffer  = $args{buffer} || \my $anon;
    my $croak   = defined $args{croak} ? $args{croak} : 1;

    unshift @{$command}, 'svn';
    my $ok = run( command => $command, buffer => $buffer);

    if ($croak and not $ok) {
        # Truncate the '-m MESSAGE' arguments, for readability
        my $dash_m_offset = firstidx {$_ eq '-m'} @{ $command };
        splice @{ $command }, $dash_m_offset + 1, 1, q{'...'};
        my $command_string = join ' ', @{ $command };
        croak "Command failed: $command_string\n". ${$buffer};
    }

    return $ok;
}

#--------------------------------------------------------------------------

1;

__END__
