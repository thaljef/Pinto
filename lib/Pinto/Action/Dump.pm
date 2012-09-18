# ABSTRACT: Dump repository contents and revision history to a file

package Pinto::Action::Dump;

use Moose;
use MooseX::Types::Moose qw(Int Str);

use JSON;
use DateTime;
use Path::Class;
use File::Temp;
use File::Which qw(which);
use File::Basename qw(basename);
use Cwd::Guard qw(cwd_guard);

use Pinto::Types qw(File);
use Pinto::Exception qw(throw);

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

extends qw( Pinto::Action );

#------------------------------------------------------------------------------

with qw( Pinto::Role::PathMaker );

#------------------------------------------------------------------------------

has outfile => (
    is      => 'ro',
    isa     => File,
    default => sub { file('pinto-dump-' . DateTime->now->strftime('%Y%m%d-%H%M%S') . '.tar.gz') },
    coerce  => 1,
    lazy    => 1,
);


has dumpversion => (
   is       => 'ro',
   isa      => Int,
   default  => 1,
   init_arg => undef,
);


has tar_exe => (
    is      => 'ro',
    isa     => Str,
    default => sub { which('tar') || throw 'Could not find tar in PATH' },
);

#------------------------------------------------------------------------------

override execute => sub {
    my ($self) = @_;

    my $temp    = File::Temp->newdir;
    my $base    = basename($self->outfile->basename, qw(.tar.gz .tgz));
    my $dumpdir = dir($temp->dirname)->subdir($base);

    # If the $outfile was "foo/bar/pinto-dump-YYMMDD.tar.gz" then
    # $dumpdir is now something like /tmp/XXXXXX/pinto-dump-YYMMDD

    $self->mkpath($dumpdir);
    $self->_dump_meta($dumpdir);
    $self->_dump_changes($dumpdir);
    $self->_dump_distributions($dumpdir);
    $self->_dump_manifest($dumpdir);
    $self->_link_authors_dir($dumpdir);
    $self->_create_dumpfile($dumpdir);

    return $self->result;
};

#------------------------------------------------------------------------------

sub _dump_meta {
    my ($self, $dumpdir) = @_;

    $self->notice("Dumping repository metadata");

    my $meta = { created_on    => time,
                 created_by    => $self->username,
                 dump_version  => $self->dumpversion,
                 pinto_version => $self->VERSION };

    my $json = JSON->new->pretty->encode($meta);

    my $meta_fh = $dumpdir->file('META.json')->openw;
    print {$meta_fh} $json;
    $meta_fh->close;

    return $self;
}

#------------------------------------------------------------------------------

sub _dump_manifest {
    my ($self, $dumpdir) = @_;

    $self->notice("Writing archive manifest");
    my $mani = [];

    my $dists_rs = $self->repos->db->select_distributions;
    while (my $dist = $dists_rs->next) {
        push @{ $mani }, $dist->path;
    }

    # Include metadata files in the manifest too
    unshift @{ $mani }, $self->_metafiles;

    my $json = JSON->new->pretty->encode($mani);

    my $meta_fh = $dumpdir->file('MANIFEST.json')->openw;
    print {$meta_fh} $json;
    $meta_fh->close;

    return $self;
}

#------------------------------------------------------------------------------

sub _dump_changes {
    my ($self, $dumpdir) = @_;

    $self->notice("Dumping repository revision history");
    my $hist = [];


    my $stack_rs = $self->repos->db->select_stacks;
    while (my $stack = $stack_rs->next) {

        $self->info("Dumping revision history for stack $stack");
        my $stack_struct = {stack_name => $stack->name, revisions => []};

        my $revision_rs = $self->repos->db->select_revisions;
        while (my $revision = $revision_rs->next) {

            my $revision_struct = { message      => $revision->message,
                                    number       => $revision->number,
                                    committed_by => $revision->committed_by,
                                    committed_on => $revision->committed_on,
                                    changes => [] };

            my $registration_changes_rs = $revision->registration_changes_rs;
            while (my $change = $registration_changes_rs->next) {

                my $pkg = $change->package;
                my $change_struct = { package      => $pkg->name,
                                      version      => $pkg->version->stringify,
                                      distribution => $pkg->distribution->path,
                                      is_pinned    => $change->is_pinned,
                                      event        => $change->event };

                push @{ $revision_struct->{changes} }, $change_struct;
            }

            push @{ $stack_struct->{revisions} }, $revision_struct;
        }

        push @{ $hist }, $stack_struct;
    }

    my $changes_fh = $dumpdir->file('CHANGES.json')->openw;
    print $changes_fh JSON->new->pretty->encode($hist);
    close $changes_fh;

    return $self;
}

#------------------------------------------------------------------------------

sub _dump_distributions {
    my ($self, $dumpdir) = @_;

    my $distributions = [];

    my $distributions_rs = $self->repos->db->select_distributions;
    while (my $dist = $distributions_rs->next) {

        my $dist_struct = { author  => $dist->author,
                            archive => $dist->path,
                            source  => $dist->source,
                            mtime   => $dist->mtime,
                            sha256  => $dist->sha256,
                            md5     => $dist->md5 };

        push @{ $distributions }, $dist_struct;
    }

    my $archives_fh = $dumpdir->file('DISTRIBUTIONS.json')->openw;
    print $archives_fh JSON->new->pretty->encode($distributions);
    close $archives_fh;

    return $self;
}

#------------------------------------------------------------------------------

sub _link_authors_dir {
    my ($self, $dumpdir) = @_;

    my $dump_authors_dir = $dumpdir->subdir('authors');
    $self->mkpath( $dump_authors_dir );

    my $abs_repos_authors_id_dir = $self->repos->config->authors_id_dir->absolute;
    my $dump_authors_id_dir = $dump_authors_dir->subdir('id');

    my $ok = symlink $abs_repos_authors_id_dir, $dump_authors_id_dir;
    $self->fatal("symlink failed: $!") if not $ok;

    return $self;
}

#------------------------------------------------------------------------------

sub _create_dumpfile {
    my ($self, $dumpdir) = @_;

    my $outfile = $self->outfile;
    $self->info("Creating dump file at $outfile");
    my $abs_outfile = $outfile->absolute;

    my @cmd = ($self->tar_exe, qw(-c -z -L -f), $abs_outfile, $dumpdir->basename);
    $self->debug('Creating dump file: ' . join ' ', @cmd);

    my $cwd_guard = cwd_guard($dumpdir->parent->stringify);
    my $ok = not system @cmd;

    $self->fatal("tar command failed: $!") if not $ok;
}


#------------------------------------------------------------------------------

sub _metafiles {

  return qw(MANIFEST.json DISTRIBUTIONS.json CHANGES.json META.json);

}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------

1;

__END__
