# ABSTRACT: Locate targets using Stratopan services

package Pinto::Locator::Stratopan;

use Moose;
use MooseX::StrictConstructor;
use MooseX::MarkAsMethods ( autoclean => 1 );

use URI;
use JSON qw(decode_json);
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

	return $self->_locate_any(%args);
}

#-----------------------------------------------------------------------------

sub locate_distribution {
	my ($self, %args) = @_;

	return $self->_locate_any(%args);
}

#-----------------------------------------------------------------------------

sub _locate_any {
	my ($self, %args) = @_;

	my $uri = $PINTO_STRATOPAN_LOCATOR_URI->clone;
	$uri->query_form(q => $args{target}->to_string);
	my $response = $self->request(GET($uri));

	if (!$response->is_success) {
		my $status = $response->status_line;
		whine "Stratopan is not responding: $status";
		return;
	}

	my $structs = eval { decode_json($response->content) };
	whine "Invalid response from Stratopan: $@" and return if $@;

	return unless my $latest = $structs->[0];

	# Avoid autovivification here...
	$latest->{version} = version->parse($latest->{version})
		if exists $latest->{version};

	# Avoid autovivification here...
	$latest->{uri} = URI->new($latest->{uri})
		if exists $latest->{uri};

	return $latest;
}

#-----------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#-----------------------------------------------------------------------------
1;

__END__