package Pinto::Action::Add;

# ABSTRACT: Add one distribution to the repository

use Moose;
use MooseX::Types::Moose qw(Bool Str);

use Path::Class;

use Pinto::Util;
use Pinto::Types qw(File StackName);
use Pinto::PackageExtractor;
use Pinto::Exceptions qw(throw_error);

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------
# ISA

extends 'Pinto::Action';

#------------------------------------------------------------------------------
# Attrbutes

has archive => (
    is       => 'ro',
    isa      => File,
    required => 1,
    coerce   => 1,
);


has norecurse => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);


has pin   => (
    is      => 'ro',
    isa     => 'Maybe[Str]',
    default => undef,
);


has stack => (
    is      => 'ro',
    isa     => StackName,
    default => 'default',
);

#------------------------------------------------------------------------------
# Roles

with qw( Pinto::Interface::Authorable
         Pinto::Role::PackageImporter
);

#------------------------------------------------------------------------------
# Public methods

override execute => sub {
    my ($self) = @_;

    my ($dist) = $self->repos->add_distribution( archive   => $self->archive,
                                                 author    => $self->author,
                                                 stack     => $self->stack,
                                                 pin       => $self->pin );

    $self->add_message( Pinto::Util::added_dist_message($dist) );

    unless ( $self->norecurse() ) {
        my $root = $self->repos->root_dir();
        my @imported = $self->import_prerequisites( $dist->archive($root), $self->stack() );
        $self->add_message( Pinto::Util::imported_prereq_dist_message($_) ) for @imported;
    }

    return 1;
};

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#-----------------------------------------------------------------------------
1;

__END__
