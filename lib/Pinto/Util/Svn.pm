package Pinto::Util::Svn;

use strict;
use warnings;

use Carp qw(croak);
use IPC::Cmd 0.72 qw(run can_run);
use File::Spec::Functions qw(catdir catfile no_upwards);
use File::Basename qw(dirname);
use File::Glob qw(bsd_glob);
use List::MoreUtils qw(all);

#--------------------------------------------------------------------------

use base 'Exporter';

our @EXPORT_OK = qw(svn_mkdir svn_ls svn_add svn_delete svn_commit svn_tag svn_schedule svn_checkout);
our %EXPORT_TAGS = (all => \@EXPORT_OK);

#--------------------------------------------------------------------------

BEGIN { can_run('svn') or croak 'svn is not available' };

#--------------------------------------------------------------------------

sub svn_mkdir {
    my %args = @_;
    my $url = $args{url};
    my $message = $args{message};

    if ( not svn_ls(url => $url) ) {
        return _svn( command => [qw(mkdir --parents -m), $message, $url]);
    }

    return 1;
}

#--------------------------------------------------------------------------

sub svn_ls {
    my %args = @_;
    my $url  = $args{url};

    return _svn( command => ['ls', $url], croak => 0 );
}

#--------------------------------------------------------------------------

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

sub svn_schedule {
    my %args = @_;
    my $path = $args{path};

    my $buffer = '';
    _svn(command => ['status', $path], buffer => \$buffer);

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
            warn "Unexpected status: $status for file $path";
        }
    }

    return 1;
}

#--------------------------------------------------------------------------

sub svn_add {
    my %args = @_;
    my $path = $args{path};

    return _svn( command => ['add', $path] );
}

#--------------------------------------------------------------------------

sub svn_delete {
    my %args  = @_;
    my $path  = $args{path};
    my $prune = $args{prune};

    _svn( command => ['rm', $path] );

    if($prune) {
        my $dir = dirname($path);
        if ( _all_scheduled_for_deletion( directory => $dir) ) {
            svn_delete(path => $dir, prune => 1);
        }
    }
}

#--------------------------------------------------------------------------

sub svn_commit {
    my %args     = @_;
    my $paths    = $args{paths};
    my $message  = $args{message};

    my @paths = ref $paths ? @$paths : ($paths);
    return _svn(command => [qw(commit -m), $message, @paths] );
}

#--------------------------------------------------------------------------

sub svn_tag {
    my %args = @_;
    my $from    = $args{from};
    my $to      = $args{to};
    my $message = $args{message};

    return _svn(command => [qw(cp --parents -m), $message, $from, $to]);
}

#--------------------------------------------------------------------------

sub _url_for_wc_path {
    my %args = @_;
    my $path = $args{path};

    my $buffer = '';
    _svn( command => ['info', $path], buffer => \$buffer);

    $buffer =~ /^URL:\s+(\S+)$/m
        or die "Unable to parse svn info: $buffer";

    return $1;
}

#--------------------------------------------------------------------------

sub _is_svn_working_copy {
    my %args = @_;
    my $directory = $args{directory};

    return -e catdir($directory, '.svn');
}

#--------------------------------------------------------------------------

sub _all_scheduled_for_deletion {
    my %args      = @_;
    my $directory = $args{directory};

    my $buffer = '';
    _svn(command => ['status', $directory], buffer => \$buffer);

    return all { /^D/ } split /\n/, $buffer;
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
        my $command_string = join ' ', map { /\s/ ? qq<'$_'> : $_ } @{$command};
        croak "Command failed: $command_string\n". ${$buffer};
    }

    return $ok;
}

#--------------------------------------------------------------------------
