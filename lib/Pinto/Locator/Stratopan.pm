# ABSTRACT: Locate targets using Stratopan services

package Pinto::Locator::Stratopan;

use Moose;
use MooseX::StrictConstructor;
use MooseX::MarkAsMethods ( autoclean => 1 );

use JSON qw(decode_json);
use URI::Escape qw(uri_escape);
use HTTP::Request::Common;

#-----------------------------------------------------------------------------

# VERSION

#-----------------------------------------------------------------------------

extends qw(Pinto::Locator);

#-----------------------------------------------------------------------------

my $stratopan_base_url = URI->new('http://meta.stratopan.com/locate');

#-----------------------------------------------------------------------------

sub locate_package {
	my ($self, %args) = @_;

	my $target = $args{target};
	my $url = $self->build_query_url("$target")
	my $res = $self->request(GET(url));
	my $struct = decode_json($res->content);
}

#-----------------------------------------------------------------------------

sub locate_distribution {
	my ($self, %args) = @_;

	my $target = $args{target};
	my $url = $self->build_query_url("$target")
	my $res = $self->request(GET(url));
	my $struct = decode_json($res->content);
	
}

#-----------------------------------------------------------------------------

sub build_query_url {
	my ($self, $query) = @_;

	return sprintf "%s&q=%s", $stratopan_base_url, uri_escape($target);
}

#-----------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#-----------------------------------------------------------------------------
1;

__END__