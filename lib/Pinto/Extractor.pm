package Pinto::Extractor;

# ABSTRACT: Extract package names and versions from a distribution

use Moose;

use Try::Tiny;
use Dist::Metadata 0.922;
use Pinto::Exceptions qw(throw_error);

use namespace::autoclean;

#-----------------------------------------------------------------------------

# VERSION

#-----------------------------------------------------------------------------
# Moose attributes

#-----------------------------------------------------------------------------
# Roles

with qw( Pinto::Role::Loggable
         Pinto::Role::Configurable );

#-----------------------------------------------------------------------------

sub extract_packages {
    my ($self, %args) = @_;

    # Must stringify, cuz D::M doesn't like Path::Class objects
    my $archive = $args{archive}->stringify();
    my $provides;

    $self->debug("Extracting packages from $archive");

    try   { $provides = Dist::Metadata->new(file => $archive)->package_versions(); }
    catch { throw_error "Unable to extract packages from $archive: $_" };

    return map { {name => $_, version => $provides->{$_}} } keys %{ $provides }
}

#-----------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#-----------------------------------------------------------------------------

1;

__END__
