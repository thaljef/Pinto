# ABSTRACT: Extract stacks to directory or archive

package Pinto::Action::Export;

use Moose;
use MooseX::StrictConstructor;
use MooseX::Types::Moose qw(Str);
use MooseX::MarkAsMethods ( autoclean => 1 );

use Try::Tiny;
use Path::Class;

use Pinto::Util qw(throw mksymlink);
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
   my ($self, $stack, $output, $modules) = @_;

   # authors' basics
   my $mailrc = '01mailrc.txt.gz';
   $output->insert($stack->authors_dir()->file($mailrc), file(authors => $mailrc));

   # modules
   my $modules_from = $stack->modules_dir();
   $output->insert($modules_from->file($_), $modules->file($_))
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

sub export_single {
    my ($self, $output) = @_;
    my ($stack) = $self->stacks();
    $self->_export_stack($stack, $output, dir('modules'));
    return;
}

sub export_multiple {
    my ($self, $output) = @_;

    for my $stack ($self->stacks()) {
        $self->_export_stack($stack, $output, dir(stacks => $stack => 'modules'));
        $output->link(
            dir(stacks => $stack => 'authors'),
            dir(qw< .. .. authors >)
        );
    }

    if (defined(my $default = $self->default_stack())) {
        $output->link(
            dir(qw< modules >),
            dir(stacks => $default => 'modules'),
        );
    }

    return;
}

sub execute {
    my ($self) = @_;
    my @stacks = $self->stacks();

    # FIXME handle locking/unlocking
    my $output = $self->_get_output_channel();
    if (scalar(@stacks) == 1) {
        $self->export_single($output);
    }
    else {
        $self->export_multiple($output);  # re-create some "Pinto"-experience
    }
    $output->close();

    # pack to target archive if necessary
    #$self->_pack($wdir) if $self->output_format() ne 'directory';

    return $self->result();
}

sub _get_output_channel {
   my ($self) = @_;

   my $classname = 'Pinto::Action::Export::' . ucfirst(lc($self->output_format()));
   (my $packpath = $classname . '.pm') =~ s{::}{/}gmxs;
   require $packpath;

   return $classname->new(exporter => $self);
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
