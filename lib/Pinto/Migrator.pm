# ABSTRACT: Migrate an existing repository to a new version

package Pinto::Migrator;

use Moose;
use MooseX::StrictConstructor;
use MooseX::MarkAsMethods ( autoclean => 1 );

use Pinto::Types qw(Dir);
use Pinto::Repository;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

has root => (
    is      => 'ro',
    isa     => Dir,
    default => $ENV{PINTO_REPOSITORY_ROOT},
    coerce  => 1,
);

#------------------------------------------------------------------------------

sub migrate {
    my ($self) = @_;

    my $repo = Pinto::Repository->new( root => $self->root );

    my $repo_version = $repo->get_version;
    my $code_version = $Pinto::Repository::REPOSITORY_VERSION;

    die "This repository is too old to migrate.\n" . "Contact thaljef\@cpan.org for a migration plan.\n"
        if not $repo_version;

    die "This repository is already up to date.\n"
        if $repo_version == $code_version;

    die "This repository too new.  Upgrade Pinto instead.\n"
        if $repo_version > $code_version;

    die "Migration is not implemented yet\n";
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------

1;

__END__
