# ABSTRACT: Dump complete repository contents and stack history

package Pinto::Action::Dump;

use Moose;
use MooseX::Types::Moose qw(Int);

use JSON;
use DateTime;
use Path::Class;
use File::Temp;
use File::Basename qw(basename);
use Cwd::Guard qw(cwd_guard);

use Pinto::Types qw(File);

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
    lazy    => 1,
);


has dumpversion => (
   is       => 'ro',
   isa      => Int,
   default  => 1,
   init_arg => undef,
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
    $self->_dump_archives($dumpdir);
    $self->_dump_history($dumpdir);
    $self->_dump_meta($dumpdir);
    $self->_dump_manifest($dumpdir);
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
    unshift @{ $mani }, qw(MANIFEST.json HISTORY.json META.json);

    my $json = JSON->new->pretty->encode($mani);

    my $meta_fh = $dumpdir->file('MANIFEST.json')->openw;
    print {$meta_fh} $json;
    $meta_fh->close;

    return $self;
}

#------------------------------------------------------------------------------

sub _dump_history {
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

            my $registration_histories_rs = $revision->registration_histories_rs;
            while (my $change = $registration_histories_rs->next) {

                my $pkg = $change->package;
                my $change_struct = { package      => $pkg->name,
                                      version      => $pkg->version->stringify,
                                      distribution => $pkg->distribution->path,
                                      is_pinned    => $change->is_pinned,
                                      action       => $change->action };

                push @{ $revision_struct->{changes} }, $change_struct;
            }

            push @{ $stack_struct->{revisions} }, $revision_struct;
        }

        push @{ $hist }, $stack_struct;
    }

    my $history_fh = $dumpdir->file('HISTORY.json')->openw;
    print $history_fh JSON->new->pretty->encode($hist);
    close $history_fh;

    return $self;
}

#------------------------------------------------------------------------------

sub _dump_archives {
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

    # TODO: Replace this with Archive::Tar::Wrapper
    my $cwd_guard = cwd_guard($dumpdir->parent->stringify);
    my $ok = not system qw(tar -c -z -L -f), $abs_outfile, $dumpdir->basename;
    $self->fatal("tar command failed: $!") if not $ok;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------

1;

__END__
