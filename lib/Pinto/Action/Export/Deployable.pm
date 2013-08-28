# ABSTRACT: generate deployable perl program as Export action

package Pinto::Action::Export::SystemTar;

use Moose;
use MooseX::StrictConstructor;
use MooseX::Types::Moose qw(Str);
use MooseX::MarkAsMethods (autoclean => 1);

use Try::Tiny;
use Path::Class;
use Data::Dumper;
use Capture::Tiny qw< capture >;
use File::Which qw< which >;
use File::Temp qw< tempfile >;

use Pinto::Util qw(mksymlink);
use Pinto::Action::Export::Tar;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

with 'Pinto::Action::Export::ExporterRole';

has base => (
   is      => 'ro',
   default => sub {
      my ($fh, $filename) = tempfile();
      close $fh;
      return $filename;
   },
);

has archive => (
   is      => 'ro',
   lazy    => 1,
   default => sub {
      my $self = shift;
      my $base = file($self->base());
      return Pinto::Action::Export::Tar->new(
         path     => $base,
         exporter => $self->exporter(),
      );
   },
);

has remote => (
   is => 'ro',
   lazy => 1,
   default => sub {
      local $/;
      binmode DATA;
      return <DATA>;
   },
);

#------------------------------------------------------------------------------

sub insert {    # proxy to archive
   my ($self, $source, $destination) = @_;
   return $self->archive()->insert($source, $destination);
}

#------------------------------------------------------------------------------

sub link {      # proxy to archive
   my ($self, $from, $to) = @_;
   return $self->archive()->link($from, $to);
}

#------------------------------------------------------------------------------

sub close {
   my ($self) = @_;

   my $archive = $self->archive();
   $archive->insert(file(__FILE__)->parent()->file('premote'), 'premote');

   $self->archive()->close();

   my $target = $self->path();
   my $base   = $self->base();

   open my $out_fh, '>:raw', $target
      or die "open('$target'): $!";
   
   print {$out_fh} $self->remote();



   return;
} ## end sub close

sub header {
   my %params   = @_;
   my $namesize = length $params{name};
   return "$namesize $params{size}\n$params{name}";
}

sub print_section {
   my ($fh, $name, $data) = @_;
   
}

sub print_configuration {
   my ($fh, $config) = @_;
   my %general_configuration;
   for my $name (qw( workdir cleanup bundle deploy gzip bzip2 passthrough )) {
      $general_configuration{$name} = $config->{$name}
        if exists $config->{$name};
   }
   my $configuration = Dumper \%general_configuration;
   print {$fh} header(name => 'config.pl', size => length($configuration)),
      "\n", $configuration, "\n\n";
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------

1;

__END__
