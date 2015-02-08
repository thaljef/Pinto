# ABSTRACT: Report distributions that are missing or broken

package Pinto::Action::Verify;

use Moose;
use MooseX::StrictConstructor;
use MooseX::MarkAsMethods ( autoclean => 1 );

use MooseX::Types::Moose qw(Int Bool);
use Pinto::Util qw(debug);
use Pinto::Verifier;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

extends qw( Pinto::Action::List );

#------------------------------------------------------------------------------

has level => (
    is       => 'ro',
    isa      => Int,
    default  => 0,
);

has local => (
    is       => 'ro',
    isa      => Bool,
    default  => 0,
);

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    my $where  = $self->_where;
    my $attrs  = $self->_attrs;
    my $method = 'search_' . ( $self->all ? 'package' : 'registration' );
    my $rs     = $self->repo->db->schema->$method( $where, $attrs );

    # XXX would be nice if I had a query that just returned unique
    # distributions, even if when we are searching for packages

    my %seen      = ();
    my $did_match = 0;
    my $errors    = 0;
    my $missing   = 0;

    RESULT:
    while ( my $it = $rs->next ) {

        # $it could be a registration or a package object, depending
        # on whether we are auditing a stack or the whole repository
        my $dist = $it->distribution;
        my $path = $dist->path;

        next RESULT if $seen{ $path }++;

        debug "Verifiying " . $dist->native_path;

        if ( not -e $dist->native_path ) {
            $self->error("Missing distribution $dist");
            $missing++;
            next RESULT;
        }
        next RESULT if $self->level == 0;

        my $verifier = Pinto::Verifier->new(
            upstream => $dist->source,
            local    => $dist->native_path,
            level    => $self->level,
        );

        if ($self->local) {
            if ( ! $verifier->verify_local ) {
                $self->error("Local checksums verification for $path failed:");
                $self->error( ">>> " . $verifier->{failure} );
                $errors++;
            }
        }
        else {
            # note we skip distributions which have no upstream
            if ( ! $dist->is_local and !$verifier->verify_upstream ) {
                $self->error("Upstream verification for $path failed");
                $self->error( ">>> " . $verifier->{failure} );
                $errors++;
            }
        }

        $self->chrome->show_progress;

        $did_match++;
    }
    $self->chrome->progress_done;

    if ($missing) {
        $self->error("$missing archive(s) are missing");
        $self->result->failed;
    }

    if (keys %$where > 1 && !$did_match) {
        $self->error("No matching archives");
        $self->result->failed;
    }

    if ($errors) {
        $self->error("$errors archive(s) failed verification");
        $self->result->failed;
    }

    return $self->result;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------

1;

__END__
