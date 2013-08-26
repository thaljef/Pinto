# ABSTRACT: support TAR archive storage for Export action, via system tar

package Pinto::Action::Export::SystemTar;

use Moose;
use MooseX::StrictConstructor;
use MooseX::Types::Moose qw(Str);
use MooseX::MarkAsMethods (autoclean => 1);

use Try::Tiny;
use Path::Class;
use Capture::Tiny qw< capture >;
use File::Which qw< which >;
use File::Temp qw< tempdir >;

use Pinto::Util qw(mksymlink);
use Pinto::Action::Export::Directory;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

with 'Pinto::Action::Export::ExporterRole';

has base => (
   is      => 'ro',
   default => sub { dir(tempdir(CLEANUP => 1)) },
);

has archive => (
   is      => 'ro',
   lazy    => 1,
   default => sub {
      my $self = shift;
      my $base = dir($self->base());
      return Pinto::Action::Export::Directory->new(
         path     => $base->subdir($self->prefix()),
         exporter => $self->exporter(),
      );
   },
);

has prefix => (
   is      => 'ro',
   lazy    => 1,
   default => sub {
      my ($self) = @_;
      return dir($self->exporter()->prefix() || '');
   },
);

has tar => (
   is      => 'ro',
   lazy    => 1,
   default => sub {
      my ($self) = @_;
      my $etar = $self->exporter()->tar();
      return $etar if defined $etar;
      return 'tar';
   },
);

has supported_compression => (
   is => 'ro',
   lazy => 1,
   default => sub {
      my ($self) = @_;
      my @supported = _check_tar($self->tar())
         or die "no system tar\n";
      return { map { $_ => 1 } @supported };
   },
);

sub _check_tar {
   my ($tar) = @_;
   my @checks = (
      {
         name => 'plain',
         opts => '',
         data => '6369616f'
           . ('00' x 96)
           . ('30' x 4)
           . '3634340'
           . ('03' x 4)
           . '13735300'
           . ('03' x 4)
           . '13735300'
           . ('03' x 11)
           . '50031323230363532343030320030313136323200203'
           . ('00' x 100)
           . '07573746172202000706f6c65747469'
           . ('00' x 25)
           . '706f6c65747469'
           . ('00' x 208)
           . '6369616f0a'
           . ('00' x 9723)
      },
      {
         name => 'gzip',
         opts => 'z',
         data => '
         1f8b08001dad1a520003edd1310a80301044d1ad3d458eb05992789e2016
         82a068bcbf0a1636221622c27fcd143bc5c0365d1ee465ba4921ece9eba8
         e73c44f1669aa2055513f53e9989d3b787ed96b9e4c9391987be2da5bbec
         dddd7faad9fe5f7d3d0200000000000000000000000000f0d80a98aba1db
         00280000
      '
      },
      {
         name => 'bzip2',
         opts => 'j',
         data => '
         425a6839314159265359daaa20f40000767b84c11002024000778000046a
         24de00000400082000741a4f4933501a341a69ea092a79350d1a0000d7ee
         26ee8415c00917c146c1e452a49034d87e99a081692421894681a10b086e
         b39463b700c99882282f57f428b0a8b0b8c6caeec1c3cd1100fc5dc914e1
         42436aa883d0
      '
      },
   );

   my @supported;

   for my $spec (@checks) {
      (my $hex = $spec->{data}) =~ s{\s+}{}gmxs;
      my $data = pack 'H*', $hex;
      my $OK = 0;
      my ($stdout, $stderr, $exit) = capture {
         try {
            open my $fh, '|-', $tar, "t$spec->{opts}f", '-'
               or die '';
            binmode $fh, ':raw';
            print {$fh} $data
               or die '';
            close $fh
               or die '';
            $OK = 1;
         };
      };
      $OK or next;
      ($exit >> 8) and next;
      push @supported, $spec->{opts};
   }

   return @supported;
} ## end sub _check_tar

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

   my $base        = $self->base();
   my $compression = $self->compression_type();
   my $tar         = $self->tar();

   system {$tar} $tar, "c${compression}f", $self->path(),
     '-C', $base, map { $_->basename() } $base->children();

   return;
} ## end sub close

#------------------------------------------------------------------------------

sub compression_type {
   my ($self) = @_;
   my $ct = {
      'tar.gz'  => 'z',
      'tgz'     => 'z',
      'tar.bz2' => 'j',
      'tbz'     => 'j',
     }->{$self->exporter()->output_format()}
     || '';
   die "unsupported compression type\n"
      unless exists $self->supported_compression()->{$ct};
   return $ct;
} ## end sub compression_type

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------

1;

__END__
