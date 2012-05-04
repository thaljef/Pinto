# ABSTRACT: Install packages from the repository

package Pinto::Action::Install;

use Moose;

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

extends qw( Pinto::Action );

#------------------------------------------------------------------------------

with qw( Pinto::Role::Interface::Action::Install );

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    # Write index to a temp location
    my $temp_index_fh = File::Temp->new;
    my $stack = $self->repos->get_stack(name => $self->stack);
    $self->repos->write_index(stack => $stack, handle => $temp_index_fh);

    # Wire cpanm to our repo
    my $opts = $self->cpanm_options;
    $opts->{'mirror-only'}  = undef;
    $opts->{'mirror-index'} = $temp_index_fh->filename;
    $opts->{mirror}         = 'file://' . $self->repos->root->absolute;

    # Process other cpanm options
    my @cpanm_opts;
    for my $opt ( keys %{ $opts } ){
        my $dashes = (length $opt == 1) ? '-' : '--';
        my $dashed_opt = $dashes . $opt;
        my $opt_value = $opts->{$opt};
        push @cpanm_opts, $dashed_opt;
        push @cpanm_opts, $opt_value if defined $opt_value && length $opt_value;
    }

    # Run cpanm
    $self->debug(join ' ', 'Running:', $self->cpanm_exe, @cpanm_opts);
    my $status = system $self->cpanm_exe, @cpanm_opts, @{ $self->targets };

    $self->result->failed if $status != 0;

    return $self->result;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#-----------------------------------------------------------------------------
1;

__END__
