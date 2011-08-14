package Pinto::Role::UserAgent;

# ABSTRACT: Something that fetches remote files

use Moose::Role;

use Carp;
use Path::Class;
use LWP::UserAgent;

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------
# Attributes

has _ua => (
    is       => 'ro',
    isa      => 'LWP::UserAgent',
    builder  => '_build_ua',
    init_arg => undef,
);

requires 'logger';

#------------------------------------------------------------------------------
# Roles

with qw(Pinto::Role::PathMaker);

#------------------------------------------------------------------------------

=method mirror(url => 'http://someplace' to => 'some/path')

Mirrors the file located at the C<url> to the file located at C<to>.
If the intervening directories do not exist, they will be created for
you.  Returns a true value if the file has changed, returns false if
it has not changed.  Throws and exception if anything goes wrong.

=cut

sub mirror {
    my ($self, %args) = @_;
    my $url = $args{url};
    my $to  = $args{to};

    $to = file($to) if not eval {$to->isa('Path::Class')};
    $self->mkpath( $to->parent() );

    $self->logger->info("Fetching $url");
    my $result = $self->_ua->mirror($url, $to);

    if ($result->is_success()) {
        return 1;
    }
    elsif($result->code == 304) {
        return 0;
    }
    else{
      croak "$url failed with status: " . $result->code();
    }
}

#------------------------------------------------------------------------------

sub _build_ua {
    my ($self) = @_;

    # TODO: Do we need to make some of this configurable?
    my $agent = sprintf "%s/%s", ref $self, 'VERSION';
    my $ua = LWP::UserAgent->new( agent      => $agent,
                                  env_proxy  => 1,
                                  keep_alive => 5 );

    return $ua;
}

#------------------------------------------------------------------------------

1;

__END__
