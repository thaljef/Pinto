# ABSTRACT: Extract stacks to directory or archive

package Pinto::Action::Export;

use Moose;
use MooseX::StrictConstructor;
use MooseX::Types::Moose qw(Str);
use MooseX::MarkAsMethods ( autoclean => 1 );

use Try::Tiny;
use Path::Class;

use Pinto::Util qw(throw mksymlink);
use Pinto::Types qw(StacksList);
use File::Copy ();

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

extends qw( Pinto::Action );

#------------------------------------------------------------------------------

has stack_names => (
    is      => 'ro',
    required => 1,
);

has _stacks => (
    is => 'rw',
    lazy => 1,
    builder => 'BUILD_stacks',
);

has default_stack => (
    is => 'ro',
    isa => Str,
    default => 0,
);

has output => (
    is      => 'ro',
    isa     => Str,
    default => 0,
);

has output_format => (
    is      => 'ro',
    isa     => Str,
    default => 0,
);

has prefix => (
    is      => 'ro',
    isa     => Str,
    default => 0,
);


#------------------------------------------------------------------------------

sub BUILD {
    my ($self) = @_;

    return $self;
}

#------------------------------------------------------------------------------

sub BUILD_stacks {
   my ($self) = @_;
   my %stack_for = map { $_ => $_ } $self->repo->get_all_stacks();
   return [ map { $stack_for{$_} } @{$self->stack_names()} ];
}

sub stacks {  # poor man's expansion, might be better in the future FIXME
   my ($self) = @_;
   return @{$self->_stacks()};
}

sub _export_stack {
   my ($self, $stack, $authors, $modules, $history) = @_;
   $history ||= {};

   # modules
   $modules->mkpath() unless -e $modules;
   my $modules_from = $stack->modules_dir();
   for my $name (qw< 02packages.details.txt.gz  03modlist.data.gz >) {
      File::Copy::copy($modules_from->file($name), $modules->file($name));
   }

   # authors' basics
   $authors->mkpath() unless -e $authors;
   my $authors_from = $stack->authors_dir();
   for my $name (qw< 01mailrc.txt.gz >) {
      my $target = $authors->file($name);
      File::Copy::copy($authors_from->file($name), $target)
         unless -e $target;
   }

   # distro files - the real meat
   my $where = { revision => $stack->head->id };
   my $attrs = { prefetch => [qw(revision package distribution)] };
   my $rs = $self->repo->db->schema->search_registration( $where, $attrs );
   my ($from_dir, $to_dir) = map { $_->subdir('id') } ($authors_from, $authors);
   while ( my $reg = $rs->next ) {
      my $distribution = $reg->distribution();
      my $path = $distribution->path;
      next if $history->{distro}{$path}++;

      my $to = $to_dir->file($path);
      my $tod = $to->parent();
      $tod->mkpath() unless -e $tod;

      my $from = $from_dir->file($path);
      File::Copy::copy($from, $to);

      next if $history->{checksum}{$tod}++;
      File::Copy::copy($from->parent()->file('CHECKSUMS'), $tod->file('CHECKSUMS'));
   }

   return;
}

sub export_single {
    my ($self, $wdir) = @_;
    $wdir ||= $self->_get_output_directory();
    my ($stack) = $self->stacks();

    # Calculate output directories for 'authors' and 'modules'
    my ($authors, $modules) = map { $wdir->subdir($_) } qw< authors modules >;

    # Call workhorse to do the heavylifting
    $self->_export_stack($stack, $authors, $modules);

    return;
}

sub export_multiple {
    my ($self, $wdir) = @_;
    $wdir ||= $self->_get_output_directory();

    # Calculate output directories for 'authors' and 'stacks'
    my ($authors, $stacks) = map { $wdir->subdir($_) } qw< authors stacks >;
    $authors->mkpath();

    my $history = {};
    for my $stack ($self->stacks()) {
        my $stack_dir = $stacks->subdir($stack);
        $stack_dir->mkpath();
        my $modules = $stack_dir->subdir('modules');
        mksymlink($stack_dir->subdir('authors'), $authors->relative($stack_dir));
        $self->_export_stack($stack, $authors, $modules, $history);
    }

    return;
}

sub execute {
    my ($self) = @_;
    my @stacks = $self->stacks();

    # FIXME handle locking/unlocking

    my $wdir = $self->_get_output_directory();
    if (scalar(@stacks) == 1) {
        $self->export_single();
    }
    else {
        $self->export_multiple();  # re-create some "Pinto"-experience
    }

    # pack to target archive if necessary
    #$self->_pack($wdir) if $self->output_format() ne 'directory';

    return $self->result();
}

sub _get_output_directory {
   my ($self) = @_;

   if ($self->output_format() eq 'directory') {
      my $dir = dir($self->output());
      $dir->mkpath();
      return $dir;
   }
      
   require File::Temp;
   # FIXME change to CLEANUP => 1
   return dir(File::Temp::tempdir(CLEANUP => 0));
}

sub _pack {
   my ($self, $directory) = @_;
   $self->error('Not supporting archives format yet, see ' . $directory);
   return;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------

1;

__END__
