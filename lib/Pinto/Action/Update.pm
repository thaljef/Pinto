package Pinto::Action::Update;

# ABSTRACT: An action to pull all the latest distributions into your repository

use Moose;

use MooseX::Types::Moose qw(Bool);

use URI;
use Try::Tiny;

use Pinto::Util;

use namespace::autoclean;

extends 'Pinto::Action';

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------
# Moose Attributes

has force => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);

#------------------------------------------------------------------------------
# Moose Roles

with qw(Pinto::Role::UserAgent);

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    my $source = $self->config->source();
    my $temp_dir = File::Temp->newdir();
    my $index_url = URI->new("$source/modules/02packages.details.txt.gz");
    my $index_temp_file = file($temp_dir, '02packages.details.txt.gz');

    $self->fetch(url => $index_url, to => $index_temp_file);
    $self->db->load_index($source, $index_temp_file);

    my $changes = 0;
    my $foreigners = $self->db->foreign_distributions();

    while (my $dist = $foreigners->next() ) {
        try   {
            $dist_changes += $self->_do_mirror($dist);
        }
        catch {
            $self->add_exception($_);
            $self->logger->whine("Download of $dist failed: $_");
        };
    }

    return 0 if not $changes;
    $self->add_message("Updated $changes distributions from $source");

    return 1;
}

#------------------------------------------------------------------------------

sub _do_mirror {
    my ($self, $dist) = @_;

    my $destination = $dist->physical_path( $self->config->repos() );
    return 0 if -e $destination;

    $self->fetch(url => $dist->url(), to => $destination) or return 0;
    $self->store->add(file => $destination);

    return 1;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#------------------------------------------------------------------------------

1;

__END__
