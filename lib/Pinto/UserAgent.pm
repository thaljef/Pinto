package Pinto::UserAgent;

use Moose;

use Carp;
use Path::Class;
use LWP::UserAgent;

#------------------------------------------------------------------------------

has _ua => (
    is       => 'ro',
    isa      => 'LWP::UserAgent',
    builder  => '_build_ua',
    init_arg => undef,
);

#------------------------------------------------------------------------------

sub mirror {
    my ($self, %args) = @_;
    my $url = $args{url};
    my $to  = $args{to};

    $to = file($to) if not eval {$to->isa('Path::Class')};
    $to->dir()->mkpath();  # TODO: set mode & verbosity

    my $ua = $self->_ua();
    my $result = $ua->mirror($url, $to);

    if ($result->is_success()) {
        return 1;
    }
    elsif($result->code == 304) {
        return 0;
    }
    else{
        croak "Mirror of $url to $to failed with status: " . $result->code();
    }
}

#------------------------------------------------------------------------------

sub _build_ua {
    my ($self) = @_;

    #$DB::single = 1;
    my $agent = sprintf "%s/%s", ref $self, 'VERSION';
    my $ua = LWP::UserAgent->new(
        agent      => $agent,
        env_proxy  => 1,
        keep_alive => 5,
    );

    return $ua;
}

#------------------------------------------------------------------------------

1;

__END__
