# ABSTRACT: Locate targets using Stratopan services

package Pinto::Locator::Stratopan;

use Moose;
use MooseX::StrictConstructor;
use MooseX::MarkAsMethods ( autoclean => 1 );

use URI;
use JSON qw(decode_json);
use URI::Escape qw(uri_escape);
use HTTP::Request::Common qw(GET);

use Pinto::Util qw(whine);
use Pinto::Constants qw(:stratopan);

#-----------------------------------------------------------------------------

# VERSION

#-----------------------------------------------------------------------------

extends qw(Pinto::Locator);

#-----------------------------------------------------------------------------

sub locate_package {
	my ($self, %args) = @_;

	my $target = $args{target};
	my $url = $self->build_query_url("$target");
	my $res = $self->request(GET($url));

	if (!$res->is_success) {
		whine "Stratopan is not responding: " . $res->status_line;
		return;
	}

	my $structs = decode_json($res->content);
	return unless my $latest = $structs->[0];

	$latest->{version} = version->parse($latest->{version});
	$latest->{url} = URI->new($latest->{url});

	return $latest;
}

#-----------------------------------------------------------------------------

sub locate_distribution {
	my ($self, %args) = @_;

	my $target = $args{target};
	my $url = $self->build_query_url("$target");
	my $res = $self->request(GET($url));

	if (!$res->is_success) {
		whine "Stratopan is not responding: " . $res->status_line;
		return;
	}

	my $structs = decode_json($res->content);
	return unless my $latest = $structs->[0];

	$latest->{version} = version->parse($latest->{version});
	$latest->{url} = URI->new($latest->{url});

	return $latest;
}

#-----------------------------------------------------------------------------

sub build_query_url {
	my ($self, $query) = @_;

	return sprintf "%s?q=%s", $PINTO_STRATOPAN_LOCATOR_URL, uri_escape($query);
}

#-----------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#-----------------------------------------------------------------------------
1;

__END__