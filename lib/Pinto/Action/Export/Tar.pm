# ABSTRACT: support TAR archive storage for Export action

package Pinto::Action::Export::Tar;

use Try::Tiny;
use Pinto::Action::Export::SystemTar;
use Pinto::Action::Export::ArchiveTar;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

sub new {
   my ($package, %params) = @_;
   my $exporter = $params{exporter};
   my $retval;
   if (! $exporter->notar()) {
      try {
         $retval = Pinto::Action::Export::SystemTar->new(%params);
         my $allowed = $retval->supported_compression();
      }
      catch {
         if (defined(my $tar = $exporter->tar())) {
            die "'$tar' does not seem to be a working tar\n";
         }
         $retval = undef;
      };
   }
   return $retval || Pinto::Action::Export::ArchiveTar->new(%params);
}

#------------------------------------------------------------------------------

1;

__END__
