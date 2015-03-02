package App::Pinto::Command::sign;

# ABSTRACT: sign all the checksums files in the repository

use strict;
use warnings;

use Pinto::Util qw(is_remote_repo);

#-----------------------------------------------------------------------------

use base 'App::Pinto::Command';

#------------------------------------------------------------------------------

# VERSION

#-----------------------------------------------------------------------------

sub opt_spec {
    my ( $self, $app ) = @_;

    return (
        [ 'gpg-homedir|d=s'    => 'The path to the GnuPG home dir to use' ],
        [ 'program-string|p=s' => 'Command string used to clearsign a file' ],
    );
}

#-----------------------------------------------------------------------------

sub validate_args {
    my ( $self, $opts, $args ) = @_;

    $self->usage_error('This command takes exactly one argument')
        if @{$args} != 1;

    return 1;
}

sub args_attribute { return 'keys' }

#-----------------------------------------------------------------------------

sub execute {
    my ( $self, $opts, $args ) = @_;

    my $global_opts = $self->app->global_options;

    die "Cannot sign CHECKSUMS on remote repositories\n"
        if is_remote_repo( $global_opts->{root} );

    return $self->next::method($opts, $args);
};

#-----------------------------------------------------------------------------

1;

__END__

=head1 SYNOPSIS

  pinto --root=REPOSITORY_ROOT sign [OPTIONS] key

=head1 DESCRIPTION

This command signs the checksums files for all distributions defined in the
repository. This is similar to what PAUSE does.  Currently we only support
GnuPG.

=head1 COMMAND ARGUMENTS

This command requires a single key identifier to specify the key to be used
with signing.  This could be the 8 character keyid of the full, quoted key
fingerprint.

=head1 COMMAND OPTIONS

=over 4

=item --gpg-homedir=PATH

=item -d PATH

Specifies the path to the GnuPG homedir containing the desied keyring and trustdb.

=item --program-string=STRING

=item -p STRING

Specify the program string used to clearsign a file.  This defaults to:

    "gpg2 --clearsign --default-key"

Note, that the key identifier will be appended to this invokation.

You will want to ensure that this command hooks into your gpg user agent
appropriately, otherwise, you will have to enter your keys passphrase many
times.

=cut
