# ABSTRACT: Extract stacks to directory or archive

package Pinto::Action::Export;

use Moose;
use MooseX::StrictConstructor;
use MooseX::Types::Moose qw(Str Bool Undef);
use MooseX::MarkAsMethods ( autoclean => 1 );

use Try::Tiny;
use Path::Class;

use Pinto::Constants qw( $PINTO_LOCK_TYPE_EXCLUSIVE );
use Pinto::Types qw( StackName StackDefault StackObject );
use Class::Load qw( load_class );

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

extends qw( Pinto::Action );

#------------------------------------------------------------------------------

has stack => (
    is       => 'rw',
    isa      => StackName | StackDefault | StackObject,
    default  => undef,
);

has output => (
    is      => 'rw',
    isa     => Str | Undef,
    default => undef,
);

has output_format => (
    is      => 'ro',
    isa     => Str,
    default => 'dir',
);

has prefix => (
    is      => 'ro',
    isa     => Str | Undef,
    default => undef,
);

has tar => (
   is => 'ro',
   isa => Str | Undef,
   default => undef,
);

has notar => (
   is => 'ro',
   isa => Bool | Undef,
   default => undef,
);


#------------------------------------------------------------------------------

sub lock_type { return $PINTO_LOCK_TYPE_EXCLUSIVE }

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    my $stack = $self->repo->get_stack($self->stack());
    my $output = $self->get_output_channel($stack);

    $self->export_stack($stack, $output);
    $output->close();

    return $self->result();
}

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

#------------------------------------------------------------------------------

sub get_output_channel {
   my ($self, $stack) = @_;

   my $of = $self->output_format();
   my $output_format = {
      deployable => {
         short_name => 'Deployable',
         extension => '.pl',
      },
      dir => {
         short_name => 'Directory',
         extension  => '',
      },
      tar => {
         short_name => 'Tar',
         extension  => '.tar',
      },
      'tar.bz2' => {
         short_name => 'Tar',
         extension  => '.tar.bz2',
      },
      'tar.gz' => {
         short_name => 'Tar',
         extension  => '.tar.gz',
      },
      tgz => {
         short_name => 'Tar',
         extension  => '.tgz',
      },
      zip => {
         short_name => 'Zip',
         extension  => '.zip',
      },
   }->{lc $of}
      or die "unsupported output format '$of'\n";

   my $output = $self->output();
   if (! defined $output) {
      $stack = $self->repo->get_stack($stack);
      my $head = $stack->head();
      $output = $stack->to_string() . '-' . $head->uuid_prefix() . $output_format->{extension};
      $self->output($output);
   }

   die "output '$output' is already present\n"
      if -e $output;

   my $class_name = 'Pinto::Action::Export::' . $output_format->{short_name};
   return load_class($class_name)->new(exporter => $self);
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------

1;

__END__
