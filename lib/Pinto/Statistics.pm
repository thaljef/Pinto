package Pinto::Statistics;

# ABSTRACT: Calculates statistics about a Pinto repository

use Moose;

use String::Format;

use Pinto::Types qw(StackName);

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------
# Attributes

has stack => (
    is      => 'ro',
    isa     => StackName,
    default => 'default',
    coerce  => 1,
);


has db => (
    is       => 'ro',
    isa      => 'Pinto::Database',
    required => 1,
);

#------------------------------------------------------------------------------
# Methods

sub total_distributions {
    my ($self) = @_;

    return $self->db->select_distributions->count;
}

#------------------------------------------------------------------------------

sub stack_distributions {
    my ($self) = @_;

    my $where = { 'stack.name' => $self->stack() };
    my $attrs = { select   => 'distribution.path',
                  join     => [ 'stack', { 'package' => 'distribution' } ],
                  distinct => 1 };

    return $self->db->select_registries( $where, $attrs )->count;
}

#------------------------------------------------------------------------------

sub total_packages {
    my ($self) = @_;

    return $self->db->select_packages->count();
}

#------------------------------------------------------------------------------

sub stack_packages {
    my ($self) = @_;

    my $where = { 'stack.name' => $self->stack() };
    my $attrs = { join => 'stack' };

    return $self->db->select_registries( $where, $attrs )->count;
}

#------------------------------------------------------------------------------

# TODO: Other statistics to consider...
#
# foreign packages (total/indexed)
# local   packages (total/indexed)
# foreign dists    (total/indexed)
# local   dists    (total/indexed)
# avg pkgs per dist
# avg # pkg revisions
# authors
# most prolific author
# N most recently added dist

#------------------------------------------------------------------------------

sub to_formatted_string {
    my ($self, $format) = @_;

    my %fspec = (
        'D' => sub { $self->total_distributions()   },
        'd' => sub { $self->stack_distributions()   },
        'k' => sub { $self->stack()                 },
        'P' => sub { $self->total_packages()        },
        'p' => sub { $self->stack_packages()        },
    );

    $format ||= $self->default_format();
    return String::Format::stringf($format, %fspec);
}

#------------------------------------------------------------------------------

sub default_format {
    my ($self) = @_;

    return <<'END_FORMAT';

STATISTICS FOR THE "%k" STACK
-------------------------------------

                     Stack      Total
               ----------------------
     Packages  %10p  %10P
Distributions  %10d  %10D
END_FORMAT

}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#------------------------------------------------------------------------------
1;

__END__


