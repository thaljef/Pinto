# ABSTRACT: A registration from a past revision

package Pinto::RegistrationSnapshot;

use Moose;
use MooseX::Types::Moose qw(Bool);

use String::Format;

use Pinto::Exception qw(throw);

use overload ( '""'  => 'to_string' );

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

has package    => (
    is         => 'ro',
    isa        => 'Pinto::Schema::Result::Package',
    required   => 1,
);


has is_pinned  => (
    is         => 'ro',
    isa        => Bool,
    required   => 1,
);

#------------------------------------------------------------------------------

sub to_string {
    my ($self, $format) = @_;

    # my ($pkg, $file, $line) = caller;
    # warn __PACKAGE__ . " stringified from $file at line $line";

    my %fspec = (
         n => sub { $self->package->name                                              },
         N => sub { $self->package->vname                                             },
         v => sub { $self->package->version                                           },
         m => sub { $self->package->distribution->is_devel  ? 'd' : 'r'               },
         p => sub { $self->package->distribution->path                                },
         P => sub { $self->package->distribution->native_path                         },
         f => sub { $self->package->distribution->archive                             },
         s => sub { $self->package->distribution->is_local  ? 'l' : 'f'               },
         S => sub { $self->package->distribution->source                              },
         a => sub { $self->package->distribution->author                              },
         A => sub { $self->package->distribution->author_canonical                    },
         d => sub { $self->package->distribution->name                                },
         D => sub { $self->package->distribution->vname                               },
         w => sub { $self->package->distribution->version                             },
         u => sub { $self->package->distribution->url                                 },
         y => sub { $self->is_pinned                        ? '+' : ' '               },
    );

    # Some attributes are just undefined, usually because of
    # oddly named distributions and other old stuff on CPAN.
    no warnings 'uninitialized';  ## no critic qw(NoWarnings);

    $format ||= $self->default_format();
    return String::Format::stringf($format, %fspec);
}


#-------------------------------------------------------------------------------

sub default_format {

    return '%y %a/%f/%N';
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#-----------------------------------------------------------------------------

1;

__END__

