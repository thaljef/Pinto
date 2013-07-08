# ABSTRACT: Unpack an archive into a temporary directory

package Pinto::ArchiveUnpacker;

use Moose;
use MooseX::StrictConstructor;
use MooseX::Types::Moose qw(Bool);
use MooseX::MarkAsMethods ( autoclean => 1 );

use Cwd qw(getcwd);
use Cwd::Guard qw(cwd_guard);
use Path::Class qw(dir);
use Archive::Extract;
use File::Temp;

use Pinto::Types qw(File);
use Pinto::Util qw(debug throw);

#-----------------------------------------------------------------------------

# VERSION

#-----------------------------------------------------------------------------

has archive => (
    is       => 'ro',
    isa      => File,
    required => 1,
    coerce   => 1,
);

has temp_dir => (
    is      => 'ro',
    isa     => 'File::Temp::Dir',
    default => sub { File::Temp->newdir( CLEANUP => $_[0]->cleanup ) },
    lazy    => 1,
);

has cleanup => (
    is      => 'ro',
    isa     => Bool,
    default => 1,
);

#-----------------------------------------------------------------------------

sub unpack {
    my ($self) = @_;

    my $archive   = $self->archive;
    my $temp_dir  = $self->temp_dir->dirname;
    my $cwd_guard = cwd_guard(getcwd);          # Archive::Extract will chdir

    local $Archive::Extract::PREFER_BIN = 1;
    local $Archive::Extract::DEBUG = 1 if ( $ENV{PINTO_DEBUG} || 0 ) > 1;

    my $ae = Archive::Extract->new( archive => $archive );

    debug "Unpacking $archive into $temp_dir";

    my $ok = $ae->extract( to => $temp_dir );
    throw "Failed to unpack $archive: " . $ae->error if not $ok;

    my @children = dir($temp_dir)->children;
    return @children == 1 ? $children[0] : dir($temp_dir);
}

#-----------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#-----------------------------------------------------------------------------

1;

__END__
