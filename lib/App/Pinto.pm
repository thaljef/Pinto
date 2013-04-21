# ABSTRACT: Command-line driver for Pinto

package App::Pinto;

use strict;
use warnings;

use Class::Load;
use App::Cmd::Setup -app;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

sub global_opt_spec {

    return (
        [ 'root|r=s'           => 'Path to your repository root directory'  ],
        [ 'no-color|no-colour' => 'Do not colorize any output'              ],
        [ 'password|p=s'       => 'Password for server authentication'      ],
        [ 'quiet|q'            => 'Only report fatal errors'                ],
        [ 'username|u=s'       => 'Username for server authentication'      ],
        [ 'verbose|v+'         => 'More diagnostic output (repeatable)'     ],
    );
}

#------------------------------------------------------------------------------

sub pinto {
    my ($self) = @_;

    return $self->{pinto} ||= do {
        my $global_options = $self->global_options;

        $global_options->{root} ||= $ENV{PINTO_REPOSITORY_ROOT}
            || $self->usage_error('Must specify a repository root');

        $global_options->{password} = $self->_prompt_for_password
            if defined $global_options->{password} and $global_options->{password} eq '-';

        my $pinto_class = $self->pinto_class_for($global_options->{root});
        Class::Load::load_class($pinto_class);

        $pinto_class->new( %{ $global_options } );
    };
}

#------------------------------------------------------------------------------

sub pinto_class_for {
    my ($self, $root) = @_;
    return $root =~ m{^http://}x ? 'Pinto::Remote' : 'Pinto';
}

#------------------------------------------------------------------------------

sub _prompt_for_password {
   my ($self) = @_;

   require Encode;
   require Term::Prompt;

   my $input    = Term::Prompt::prompt('p', 'Password:', '', '');
   my $password = Encode::decode_utf8($input);
   print "\n"; # Get on a new line

   return $password;
}

#-------------------------------------------------------------------------------


1;

__END__

=head1 DESCRIPTION

App::Pinto is the command-line driver for Pinto.  It is just a
front-end.  To do anything useful, you'll also need to install one of
the back-ends, which ship separately.  If you need to create
repositories and/or work directly with repositories on the local disk,
then install L<Pinto>.  If you already have a repository on a remote
host that is running L<pintod>, then install L<Pinto::Remote>.  If
you're not sure what you need, then install L<Task::Pinto> to get the
whole kit.

=head1 SEE ALSO

L<pinto> to create and manage a Pinto repository.

L<pintod> to allow remote access to your Pinto repository.

L<Pinto::Manual> for general information on using Pinto.

L<Stratopan|http://stratopan.com> for hosting your Pinto repository in the cloud.

=cut
