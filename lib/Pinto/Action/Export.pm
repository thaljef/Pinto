# ABSTRACT: Extract stacks to directory or archive

package Pinto::Action::Export;

use Moose;
use MooseX::StrictConstructor;
use MooseX::Types::Moose qw(Str);
use MooseX::MarkAsMethods ( autoclean => 1 );

use Try::Tiny;
use Path::Class;

use Pinto::Constants qw( $PINTO_LOCK_TYPE_EXCLUSIVE );
use Pinto::Types qw( StackName );
use Class::Load qw( load_class );

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

extends qw( Pinto::Action );

#------------------------------------------------------------------------------

has stack => (
    is       => 'ro',
    isa      => StackName,
    required => 1,
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

sub lock_type { return $PINTO_LOCK_TYPE_EXCLUSIVE }

#------------------------------------------------------------------------------

sub export_stack {
   my ($self, $stack, $output, $modules_to) = @_;
   $stack = $self->repo->get_stack($stack);
   $modules_to = dir('modules') unless defined $modules_to;

   # authors' basics
   my $mailrc = '01mailrc.txt.gz';
   $output->insert($stack->authors_dir()->file($mailrc), file(authors => $mailrc));

   # modules
   my $modules_from = $stack->modules_dir();
   $output->insert($modules_from->file($_), $modules_to->file($_))
      for (qw< 02packages.details.txt.gz  03modlist.data.gz >);

   # distro files - the real meat
   my $where = { revision => $stack->head->id };
   my $attrs = { prefetch => [qw(revision package distribution)] };
   my $rs = $self->repo->db->schema->search_registration( $where, $attrs );
   my $from_dir = $stack->authors_dir()->subdir('id');
   my $to_dir = dir(qw< authors id >);
   while ( my $reg = $rs->next ) {
      my $path = $reg->distribution->path;
      my $to = $to_dir->file($path);
      my $from = $from_dir->file($path);
      $output->insert($from, $to);
      $output->insert($from->parent()->file('CHECKSUMS'), $to->parent()->file('CHECKSUMS'));
   }

   return;
}

sub execute {
    my ($self) = @_;

    my $output = $self->get_output_channel();
    $self->export_stack($self->stack(), $output);
    $output->close();

    return $self->result();
}

sub get_output_channel {
   my ($self) = @_;

   my $of = $self->output_format();
   my $short_name = {
      dir => 'Directory',
      directory => 'Directory',
      zip => 'Zip',
      tar => 'Tar',
      # FIXME tgz => 'Tar',
   }->{lc $of}
      or die "unsupported output format '$of'\n";

   my $class_name = 'Pinto::Action::Export::' . $short_name;
   return load_class($class_name)->new(exporter => $self);
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------

1;

__END__
