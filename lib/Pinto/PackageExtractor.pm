package Pinto::PackageExtractor;

# ABSTRACT: Extract packages provided/required by a distribution archive

use Moose;

use Try::Tiny;
use Dist::Requires;
use Dist::Metadata 0.922;

use Pinto::PackageSpec;
use Pinto::Exceptions qw(throw_error);

use namespace::autoclean;

#-----------------------------------------------------------------------------

# VERSION

#-----------------------------------------------------------------------------

with qw( Pinto::Interface::Configurable
         Pinto::Interface::Loggable );

#-----------------------------------------------------------------------------

sub provides {
    my ($self, %args) = @_;

    # Must stringify, cuz D::M doesn't like Path::Class objects
    my $archive = $args{archive}->stringify();
    $self->debug("Extracting packages from $archive");

    my $provides =   try { Dist::Metadata->new(file => $archive)->package_versions()  }
                   catch { throw_error "Unable to extract packages from $archive: $_" };

    my @provides = map { Pinto::PackageSpec->new(name => $_, version => $provides->{$_}) } 
        keys %{ $provides };

    $self->debug("Archive $archive provides: " . join ' ', @provides);

    return @provides;
}

#-----------------------------------------------------------------------------

sub requires {
    my ($self, %args) = @_;

    my $archive = $args{archive};
    $self->debug("Extracting prerequisites from $archive");

    my %prereqs =   try { Dist::Requires->new()->requires(dist => $archive)               }
                  catch { throw_error "Unable to extract prerequisites from $archive: $_" };

    my @prereqs = map { Pinto::PackageSpec->new(name => $_, version => $prereqs{$_}) } 
        keys %prereqs;

    $self->debug("Archive $archive requires: " . join ' ', @prereqs);

    return @prereqs;
}

#-----------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#-----------------------------------------------------------------------------

1;

__END__
