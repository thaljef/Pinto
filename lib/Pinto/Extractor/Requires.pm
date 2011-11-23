package Pinto::Extractor::Requires;

# ABSTRACT: Extract packages required by a distribution archive

use Moose;

use Try::Tiny;
use Dist::Requires;
use Pinto::Exceptions qw(throw_error);

use namespace::autoclean;

#-----------------------------------------------------------------------------

# VERSION

#-----------------------------------------------------------------------------

extends 'Pinto::Extractor';

#-----------------------------------------------------------------------------

override extract => sub {
    my ($self, %args) = @_;

    my $archive = $args{archive};

    $self->debug("Extracting prerequisites from $archive");

    my %prereqs;
    try   { %prereqs = Dist::Requires->new()->requires(dist => $archive) }
    catch { throw_error "Unable to extract prerequisites from $archive: $_" };

    return map { {name => $_, version => $prereqs->{$_}} } keys %{ $prereqs }
};

#-----------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#-----------------------------------------------------------------------------

1;

__END__
