package Pinto::Action::Clean;

# ABSTRACT: Remove all outdated distributions from the repository

use Moose;

use MooseX::Types::Moose qw(Bool);

use IO::Interactive;

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------
# ISA

extends 'Pinto::Action';

#------------------------------------------------------------------------------

has confirm => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);

#------------------------------------------------------------------------------
# Methods

override execute => sub {
    my ($self) = @_;

    my $outdated = $self->_select_outdated_distributions();

    my $removed  = 0;
    while ( my $dist = $outdated->next() ) {
        my $path = $dist->path();
        my $archive = $dist->archive( $self->config->root_dir() );

        if ( $self->confirm() && IO::Interactive::is_interactive() ) {
            next if not $self->_prompt_for_confirmation($archive);
        }

        $self->repos->remove_distribution(path => $dist);
        $self->add_message( "Removed distribution $path" );
        $removed++;
    }

    return $removed;
};

#------------------------------------------------------------------------------

sub _select_outdated_distributions {
    my ($self) = @_;

    my $attrs = { prefetch => 'packages', order_by => {-asc => 'path'} };
    my $rs = $self->db->get_distributions(undef, $attrs);

    my @outdated;
    while ( my $dist = $rs->next() ) {
        push @outdated, $dist if none { $_->is_latest() } $dist->packages();
    }

    my $new_rs = $self->result_source->resultset();
    $new_rs->set_cache(\@outdated);

    return $new_rs;

}

#------------------------------------------------------------------------------

sub _prompt_for_confirmation {
    my ($self, $archive) = @_;

    my $answer = '';
    until ($answer =~ m/^[yn]$/ix) {
        print "Remove distribution $archive? [Y/N]: ";
        chomp( $answer = uc <STDIN> );
    }

    return $answer eq 'Y';
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#------------------------------------------------------------------------------

1;

__END__
