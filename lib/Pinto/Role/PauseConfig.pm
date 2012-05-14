# ABSTRACT: Something that has a pause config attribute

package Pinto::Role::PauseConfig;

use Moose::Role;

use MooseX::Types::Moose qw(HashRef);
use Pinto::Types qw(File);

use Path::Class;
use File::HomeDir;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

=attr pauserc

The path to your PAUSE config file.  By default, this is F<~/.pause>.

=cut

has pauserc => (
    is         => 'ro',
    isa        => File,
    lazy       => 1,
    coerce     => 1,
    builder    => '_build_pauserc',
);


#------------------------------------------------------------------------------

=method pausecfg

Returns a hashref representing the data of the PAUSE config file.

=cut

has pausecfg => (
    is        => 'ro',
    isa       => HashRef,
    lazy      => 1,
    init_arg  => undef,
    builder   => '_build_pausecfg',
);


#------------------------------------------------------------------------------

sub _build_pauserc {
    my ($self) = @_;

    return file(File::HomeDir->my_home, '.pause');
}

#------------------------------------------------------------------------------

sub _build_pausecfg {
    my ($self) = @_;

    my $cfg = {};
    return $cfg if not -e $self->pauserc();
    my $fh = $self->pauserc->openr();

    # basically taken from the parsing code used by cpan-upload
    # (maybe this should be part of the CPAN::Uploader api?)

    while (<$fh>) {
        next if /^ \s* (?: [#].*)? $/x;
        my ($k, $v) = /^ \s* (\w+) \s+ (.+?) \s* $/x;
        $cfg->{$k} = $v;
    }

    return $cfg;
}

#------------------------------------------------------------------------------
1;

=pod

=for stopwords pauserc

=cut

__END__
