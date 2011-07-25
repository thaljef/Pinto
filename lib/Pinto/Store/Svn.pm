package Pinto::Store::Svn;

# ABSTRACT: Store your Pinto repository with Subversion

use Moose;
use Pinto::Util::Svn;

extends 'Pinto::Store';

#--------------------------------------------------------------------------------------------

# VERSION

#--------------------------------------------------------------------------------------------

sub initialize {
    my ($self, %args) = @_;

    my $local = $args{local} || $self->config()->get_required('local');
    my $trunk_url = $args{trunk_url} || $self->config()->get_required('trunk_url');
    Pinto::Util::Svn::svn_checkout(url => $trunk_url, to => $local);

    return 1;
}

#--------------------------------------------------------------------------------------------

sub finalize {
    my ($self, %args) = @_;

    my $local = $args{local} || $self->config()->get_required('local');
    Pinto::Util::Svn::svn_schedule(path => $local);

    my $message = $args{message} || 'NO MESSAGE WAS GIVEN';
    Pinto::Util::Svn::svn_commit(paths => $local, message => $message);

    return 1;
}

#--------------------------------------------------------------------------------------------

1;

__END__
