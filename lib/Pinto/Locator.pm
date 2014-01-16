# ABSTRACT: Base class for Locators

package Pinto::Locator;

use Moose;
use MooseX::StrictConstructor;
use MooseX::MarkAsMethods (autoclean => 1);

use Pinto::Types qw(Dir);
use Pinto::Util qw(throw tempdir);

#------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------

with qw(Pinto::Role::UserAgent);

#------------------------------------------------------------------------

has cache_dir => (
    is         => 'ro',
    isa        => Dir,
    default    => \&tempdir,
);

#------------------------------------------------------------------------

sub locate {
    my ($self, %args) = @_;

    $args{target} || throw 'Invalid arguments';

    $args{target} = Pinto::Target->new($args{target}) 
        if not ref $args{target};

    return $self->locate_package(%args)
        if $args{target}->isa('Pinto::Target::Package');

    return $self->locate_distribution(%args)
        if $args{target}->isa('Pinto::Target::Distribution');
        
    throw 'Invalid arguments';
}

#------------------------------------------------------------------------

sub locate_package { die 'Abstract method'}

#------------------------------------------------------------------------

sub locate_distribution { die 'Abstract method'}

#------------------------------------------------------------------------

sub refresh {}

#------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------
1;

__END__
