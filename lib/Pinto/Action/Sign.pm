# ABSTRACT: Sign distribution checksum files

package Pinto::Action::Sign;

use Moose;
use MooseX::StrictConstructor;
use MooseX::MarkAsMethods ( autoclean => 1 );

use MooseX::Types::Moose qw(ArrayRef Str);
use Pinto::Types qw(Dir);
#use Pinto::Util qw(throw);
use CPAN::Checksums;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

extends qw( Pinto::Action );

#------------------------------------------------------------------------------

has keys => (
    is       => 'ro',
    isa      => ArrayRef[Str],
    required => 1,
);

has program_string => (
    is       => 'ro',
    isa      => Str,
);

has homedir => (
    is      => 'ro',
    isa     => Dir,
);

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    my $dist_rs = $self->repo->db->schema->distribution_rs;

    my $errors = 0;
    my %seen   = ();

    DISTRIBUTION:
    while ( my $dist = $dist_rs->next ) {

        my $dir = $dist->native_path->dir();

        next DISTRIBUTION if $seen{$dir};

        local $CPAN::Checksums::CAUTION     = 1;
        local $CPAN::Checksums::SIGNING_KEY = $self->keys->[0];
        local $CPAN::Checksums::SIGNING_PROGRAM
          = $self->program_string || "gpg2 --clearsign --default-key";

        my $retval = eval {
            local $ENV{GNUPGHOME}
              = $self->homedir || $ENV{PINTO_GNUPGHOME} || $ENV{GNUPGHOME};
            CPAN::Checksums::updatedir($dir);
        };
        $errors += !$retval;
    }
    $self->result->failed if $errors > 0;

    return $self->result;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------

1;

__END__
