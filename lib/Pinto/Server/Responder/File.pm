# ABSTRACT: Responder for static files

package Pinto::Server::Responder::File;

use Moose;

use Plack::Response;
use Plack::MIME;

use HTTP::Date ();

#-------------------------------------------------------------------------------

# VERSION

#-------------------------------------------------------------------------------

extends qw(Pinto::Server::Responder);

#-------------------------------------------------------------------------------

sub respond {
    my ($self) = @_;

    # e.g. /stack_name/modules/02packages.details.txt.gz
    my (undef, @path_parts) = split '/', $self->request->path_info;

    my $file = $self->root->file(@path_parts);

    my @stat = stat($file);
    unless (-f _) {
        my $body = "File $file not found";
        my $headers = ['Content-Type' => 'text/plain', 'Content-Length' => length($body)];
        return [404, $headers, [$body]];
    }

    my $modified_since = HTTP::Date::str2time( $self->request->env->{HTTP_IF_MODIFIED_SINCE} );
    return [304, [], []] if $modified_since && $stat[9] <= $modified_since;

    my $response = Plack::Response->new;
    $response->content_type( Plack::MIME->mime_type($file) );
    $response->content_length( $stat[7] );
    $response->header( 'Last-Modified' => HTTP::Date::time2str($stat[9]) );

    $response->header( 'Cache-Control' => 'no-cache' ) if $self->should_not_cache($file);

    $response->body( $file->openr ) unless $self->request->method eq "HEAD";
    $response->status( 200 );

    return $response;
 }

#-------------------------------------------------------------------------------

=method should_not_cache($file)

Returns true if the file should not be cached, and therefore the Cache-Control
header should be set to 'no-cache' in the response.  Currently, only the index
files should not be cached.

=cut

#-------------------------------------------------------------------------------

sub should_not_cache {
    my ($self, $file) = @_;

    # force caches to always revalidate the indices, i.e.
    # 01mailrc.txt.gz, 02packages.details.txt.gz, 03modlist.data.gz

    my $basename = $file->basename;

    return 1 if $basename eq '01mailrc.txt.gz';
    return 1 if $basename eq '02packages.details.txt.gz';
    return 1 if $basename eq '03modlist.data.gz';
    return 0;
}

#-------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#-------------------------------------------------------------------------------

1;
