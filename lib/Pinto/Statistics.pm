package Pinto::Statistics;

# ABSTRACT: Calculates statistics about a Pinto repository

use Moose;

use String::Format;

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------
# Attributes

has db => (
    is       => 'ro',
    isa      => 'Pinto::Database',
    required => 1,
);

#------------------------------------------------------------------------------
# Methods

sub total_distributions {
    my ($self) = @_;

    return $self->db->select_distributions->count();
}

#------------------------------------------------------------------------------

sub index_distributions {
    my ($self) = @_;

    my $where = { is_latest => 1};
    my $attrs = { select => 'path', join => 'packages', distinct => 1 };

    return $self->db->select_distributions($where, $attrs)->count();
}

#------------------------------------------------------------------------------

sub total_packages {
    my ($self) = @_;

    return $self->db->select_packages->count();
}

#------------------------------------------------------------------------------

sub index_packages {
    my ($self) = @_;

    my $where = {is_latest => 1};

    return $self->db->select_packages( $where )->count();
}
#------------------------------------------------------------------------------

sub to_formatted_string {
    my ($self, $format) = @_;

    my %fspec = (
        'D' => sub { $self->total_distributions()   },
        'd' => sub { $self->index_distributions()   },
        'P' => sub { $self->total_packages()        },
        'p' => sub { $self->index_packages()        },
    );

    $format ||= $self->default_format();
    return String::Format::stringf($format, %fspec);
}

#------------------------------------------------------------------------------

sub default_format {
    my ($self) = @_;

    return <<'END_FORMAT';
                     Index      Total
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


