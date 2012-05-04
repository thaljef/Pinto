# ABSTRACT: Install packages from the repository

package Pinto::Action::Install;

use Moose;
use MooseX::Types::Moose qw(HashRef ArrayRef Str);

use Pinto::Exception qw(throw);

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

extends qw( Pinto::Action );

#------------------------------------------------------------------------------

with qw( Pinto::Role::Interface::Action );

#------------------------------------------------------------------------------


has options => (is => 'ro', isa => HashRef, default => sub { {} } );
has targets => (is => 'ro', isa => ArrayRef[Str], default => sub { [] } );

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    my $opts = $self->options;
    $opts->{'mirror-only'} = undef;
    $opts->{mirror} = 'file://' . $self->repos->root->absolute;

    my @cmd_args;
    for my $opt ( keys %{ $opts } ){
        my $dashes = (length $opt == 1) ? '-' : '--';
        my $dashed_opt = $dashes . $opt;
        my $opt_value = $opts->{$opt};
        push @cmd_args, $dashed_opt;
        push @cmd_args, $opt_value if defined $opt_value && length $opt_value;
    }


    $DB::single = 1;
    my $status = system 'cpanm', @cmd_args, @{ $self->targets };

    $self->result->failed if $status != 0;

    return $self->result;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#-----------------------------------------------------------------------------
1;

__END__
