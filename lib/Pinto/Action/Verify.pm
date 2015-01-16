# ABSTRACT: Report distributions that are missing

package Pinto::Action::Verify;

use Moose;
use MooseX::StrictConstructor;
use MooseX::MarkAsMethods ( autoclean => 1 );

use MooseX::Types::Moose qw(Bool);
use Pinto::Util qw(debug);
use Pinto::Verifier;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

extends qw( Pinto::Action::List );

#------------------------------------------------------------------------------

has strict => (
    is       => 'ro',
    isa      => Bool,
    default  => 0,
);

has files_only => (
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
    # distibutions, even if when we are searching for packages

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
        next RESULT if $self->files_only;

        my $verifier = Pinto::Verifier->new(
            upstream => $dist->source,
            local    => $dist->native_path,
            strict   => $self->strict,
        );

        # If upstream has critical errors, then it is neither safe nor valid
        # to verify the local files, but if the distribution is local then we
        # assume we trust it.
        if ( $dist->is_local or $verifier->verify_upstream ) {

            # if local copies have critical errors, it is neither safe nor
            # valid to verify any embedded signature
            if ( $verifier->verify_local ) {

                # verify the embedded signature if it exists
                if ( !$verifier->maybe_verify_embedded ) {
                    $self->error("Embeded SIGNATURE verification for $path failed");
                    $errors++;
                }
            }
            else {
                $self->error("Local checksums verification for $path failed:");
                $self->error( ">>> " . $verifier->{error_message} );
                $errors++;
            }
        }
        else {
            $self->error("Upstream checksums verification for $path failed");
            $self->error( ">>> " . $verifier->{error_message} );
            $errors++;
        }

        $did_match++;
    }

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
