package Pinto::Action::Reindex;

# ABSTRACT: Reindex one distribution in the repository

use Moose;
use MooseX::Types::Moose qw( Str );

use Pinto::Util;
use Pinto::Exceptions qw(throw_error);

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------
# ISA

extends 'Pinto::Action';

#------------------------------------------------------------------------------
# Attributes

has path  => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

#------------------------------------------------------------------------------

with qw( Pinto::Role::Authored
         Pinto::Role::Extractor );

#------------------------------------------------------------------------------

override execute => sub {
    my ($self) = @_;

    my $path    = $self->path();
    my $author  = $self->author();

    $path = $path =~ m{/}mx ?
        $path : Pinto::Util::author_dir($author)->file($path)->as_foreign('Unix');

    my $old_dist = $self->db->get_distribution_with_path($path)
        or throw_error "Distribution $path does not exist";

    return $self->_reindex($old_dist);
};

#------------------------------------------------------------------------------

sub _reindex {
    my ($self, $old_dist) = @_;

    my $path    = $old_dist->path();
    my $source  = $old_dist->source();
    my $archive = $old_dist->archive( $self->config->root_dir() );

    throw_error "Distribution $archive does not exist" if not -e $archive;

    my $txn_guard = $self->db->schema->txn_scope_guard();

    $self->repos->db->remove_distribution($old_dist);
    $self->preos->add_distribution(archive => $archive);

    $txn_guard->commit();

    $self->add_message( Pinto::Util::reindexed_dist_message( $new_dist ) );

    return 1;
};

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#------------------------------------------------------------------------------

1;

__END__
