package Pinto::Store;

# ABSTRACT: Back-end storage for a Pinto repoistory

use Moose;
use Path::Class;

#-------------------------------------------------------------------------------------------

# VERSION

#-------------------------------------------------------------------------------------------

has config => (
    is       => 'ro',
    isa      => 'Pinto::Config',
    required => 1,
);

#-------------------------------------------------------------------------------------------

sub initialize {
    my ($self, %args) = @_;
    my $local = $args{local} || $self->config()->get_required('local');
    file($local)->mkpath();
    return 1;
}

#-------------------------------------------------------------------------------------------

sub finalize {
    my ($self, %args) = @_;
    # Noting to do!
    return 1;
}


#-------------------------------------------------------------------------------------------

1;

__END__
