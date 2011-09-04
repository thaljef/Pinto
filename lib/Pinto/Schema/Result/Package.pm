package Pinto::Schema::Result::Package;

# ABSTRACT: Represents a single record in the 02packages.details.txt file

use Moose;
use MooseX::Types::Moose qw(Str);
use DBIx::Class::MooseColumns;

use overload ('""' => 'to_string');

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

extends 'DBIx::Class::Core';

#------------------------------------------------------------------------------

__PACKAGE__->table('packages');

#------------------------------------------------------------------------------

has id         => (

);

has name       => (
    is         => 'ro',
    isa        => Str,
    required   => 1,
    add_column => { data_type => 'text'},
);


has 'version' => (
    is        => 'ro',
    isa       => Str,
    required  => 1,
    add_column => { data_type => 'text'  },
);


has 'dist'    => (
    is        => 'ro',
    isa       => 'Pinto::Distribution',
    required  => 1,
);

#------------------------------------------------------------------------------

__PACKAGE__->set_primary_key('id');
__PACKAGE__->add_unique_constraint('name_idx' => ['name']);
__PACKAGE__->belongs_to('name_idx' => ['name']);

#------------------------------------------------------------------------------

=method to_string()

Returns this Package as a string containing the package name.  This is
what you get when you evaluate and Package in double quotes.

=cut

sub to_string {
    my ($self) = @_;

    return $self->name();
}

#------------------------------------------------------------------------------

=method to_index_string()

Returns this Package object as a string that is suitable for writing
to an F<02packages.details.txt> file.

=cut

sub to_index_string {
    my ($self) = @_;

    my $fw = 38 - length $self->version();
    $fw = length $self->name() if $fw < length $self->name();

    return sprintf "%-${fw}s %s  %s\n", $self->name(),
                                        $self->version(),
                                        $self->dist->location();
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable( inline_constructor => 0 );

#------------------------------------------------------------------------------

1;

__END__

=head1 DESCRIPTION

This is a private module for internal use only.  There is nothing for
you to see here (yet).

=cut
