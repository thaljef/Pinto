# ABSTRACT: generate deployable perl program as Export action

package Pinto::Action::Export::Deployable;

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

use Pinto::Util qw(mksymlink find_cpanm_exe);
use Pinto::Action::Export::Tar;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

with 'Pinto::Action::Export::ExporterRole';

has base => (
   is      => 'ro',
   default => sub {
      my ($fh, $filename) = tempfile();
      CORE::close $fh;
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

   $self->insert_premote();
   $self->insert_cpanm();
   $self->archive()->close();

   my $target = $self->path();
   my $base   = $self->base();

   open my $out_fh, '>:raw', $target
      or die "open('$target'): $!";
   
   my $sdir = file(__FILE__)->parent()->subdir('Deployable');
   copy_fh($sdir->file('dremote'), $out_fh);

   my %configuration = (
      deploy => [ 'premote' ],
   );
   my $compression = $self->exporter()->compression();
   $configuration{bzip2} = 1 if $compression eq 'bz2';
   $configuration{gzip} = 1 if $compression eq 'gz';
   print_configuration($out_fh, \%configuration);

   print_section($out_fh, 'here', { filename => $base });

   CORE::close $out_fh
      or die "close('$target'): $!\n";
   chmod 0755 &~ umask(), $target;

   return;
} ## end sub close

sub insert_premote {
   my ($self) = @_;
   my $sdir = file(__FILE__)->parent()->subdir('Deployable');

   my ($out_fh, $filename) = tempfile();
   binmode $out_fh, ':raw';

   copy_fh($sdir->file('premote'), $out_fh);

   print {$out_fh} join "\n", @{$self->exporter()->targets()}, '';

   CORE::close($out_fh)
      or die "close(): $!\n";

   my $archive = $self->archive();
   chmod 0777 &~ umask(), $filename;
   $archive->insert($filename, 'premote');
   unlink $filename;
   return;
}

sub insert_cpanm {
   my ($self)= @_;
   my $path = find_cpanm_exe();
   $path = dir($ENV{PINTO_HOME})->file(qw< etc cpanm >)->stringify()
      unless -e $path;
   $self->archive()->insert($path, 'cpanm');
   return;
}

sub copy_fh {
   my ($from_fh, $to_fh) = @_;
   if (ref($from_fh) ne 'GLOB') {
      (my $filename, $from_fh) = ($from_fh, undef);
      open $from_fh, '<:raw', $filename
         or die "open('$filename'): $!\n";
   }
   while ('necessary') {
      my $buf = '';
      my $nread = sysread $from_fh, $buf, 4096;
      die "read(): $!\n" unless defined $nread;
      return unless $nread;
      $to_fh->print($buf)
         or die "print(): $!\n";
   }
}

sub print_section {
   my ($out_fh, $name, $data) = @_;
   my $namesize = length $name;
   my $size = ref($data) ? -s $data->{filename} : length($data);
   print {$out_fh} "$namesize $size\n$name\n";
   ref($data) ? copy_fh($data->{filename}, $out_fh) : print {$out_fh} $data;
   print {$out_fh} "\n\n";
}

sub print_configuration {
   my ($out_fh, $config) = @_;
   print_section($out_fh, 'config.pl', Dumper($config));
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------

1;

__END__
