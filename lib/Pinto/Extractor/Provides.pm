package Pinto::Extractor::Provides;

# ABSTRACT: Extract packages provided by a distribution archive

use Moose;

use Try::Tiny;
use Dist::Metadata 0.922;

use Pinto::PackageSpec;
use Pinto::Exceptions qw(throw_error);

use namespace::autoclean;

#-----------------------------------------------------------------------------

# VERSION

#-----------------------------------------------------------------------------

extends 'Pinto::Extractor';

#-----------------------------------------------------------------------------

override extract => sub {
    my ($self, %args) = @_;

    # Must stringify, cuz D::M doesn't like Path::Class objects
    my $archive = $args{archive}->stringify();
    my $provides;

    $self->debug("Extracting packages from $archive");

    try   { $provides = Dist::Metadata->new(file => $archive)->package_versions(); }
    catch { throw_error "Unable to extract packages from $archive: $_" };

    return map { Pinto::PackageSpec->new(name => $_, version => $provides->{$_}) } keys %{ $provides }
};

#-----------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#-----------------------------------------------------------------------------

1;

__END__
