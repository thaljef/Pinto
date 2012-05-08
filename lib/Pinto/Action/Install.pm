# ABSTRACT: Install packages from the repository

package Pinto::Action::Install;

use Moose;
use MooseX::Types::Moose qw(HashRef ArrayRef Maybe Str);

use File::Which qw(which);

use Pinto::Exception qw(throw);

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

extends qw( Pinto::Action );

#------------------------------------------------------------------------------

has cpanm_options => (
    is      => 'ro',
    isa     => HashRef[Maybe[Str]],
    default => sub { {} },
    lazy    => 1,
);


has cpanm_exe => (
    is      => 'ro',
    isa     => Str,
    default => sub { which('cpanm') || '' },
    lazy    => 1,
);


has stack   => (
    is      => 'ro',
    isa     => Str,
);


has targets => (
    is      => 'ro',
    isa     => ArrayRef[Str],
    default => sub { [] },
    lazy    => 1,
);

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
    0 == system($self->cpanm_exe, @cpanm_opts, @{ $self->targets })
      or throw "Installation failed.  See the cpanm build log for details";

    return $self->result;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#-----------------------------------------------------------------------------
1;

__END__
