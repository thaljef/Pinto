# ABSTRACT: Internal class for Pinto::Editor

package Pinto::Editor::Edit;

use Moose;
use Try::Tiny;
use IO::File;

use Pinto::Editor::Clip;

#-----------------------------------------------------------------------------

# VERSION

#-----------------------------------------------------------------------------

our $EDITOR = 'Pinto::Editor';
our $RETRY = "__Pinto_Editor_retry__\n";
our $Test_edit;

#-----------------------------------------------------------------------------

has process => qw/ is ro isa Maybe[CodeRef] /;
has separator => qw/ is rw /;
has file => qw/ is ro required 1 /;

has document => qw/ is rw isa Str required 1 /;
has $_ => reader => $_, writer => "_$_", isa => 'Str' for qw/ initial_document /;

has preamble => qw/ is rw isa Maybe[Str] /;
has $_ => reader => $_, writer => "_$_", isa => 'Maybe[Str]' for qw/ initial_preamble /;

has content => qw/ is rw isa Str /;
has $_ => reader => $_, writer => "_$_", isa => 'Str' for qw/ initial_content /;

#-----------------------------------------------------------------------------

sub BUILD {
    my $self = shift;

    my $document = $self->document;
    $self->_initial_document( $document );

    my ( $preamble, $content ) = $self->split( $document );

    $self->preamble( $preamble );
    $self->_initial_preamble( $preamble );

    $self->content( $content );
    $self->_initial_content( $content );
}

#-----------------------------------------------------------------------------

sub edit {
    my $self = shift;

    my $file = $self->file;
    my $tmp;
    if ( blessed $file ) {
        if ( $file->isa( 'IO::Handle' ) ) {
            $tmp = $file;
        }
        elsif ( $file->isa( 'Path::Class::File' ) ) {
            $tmp = $file->open( 'w' ) or die "Unable to open $file: $!";
        }
        else {
            die "Invalid file: $file";
        }
    }
    else {
        $file = '' unless defined $file;
        if ( ref $file ) {
            die "Invalid file: $file";
        }
        elsif ( length $file ) {
            $tmp = IO::File->new( $file, 'w' ) or die "Unable to open $file: $!";
        }
        else {
            die "Missing file";
        }
    }
    $tmp->autoflush( 1 );

    while ( 1 ) {
        $tmp->seek( 0, 0 ) or die "Unable to seek on tmp ($tmp): $!";
        $tmp->truncate( 0 ) or die "Unable to truncate on tmp ($tmp): $!";
        $tmp->print( $self->join( $self->preamble, $self->content ) );

        if ( $Test_edit ) {
            $Test_edit->( $tmp );
        }
        else {
            try {
                    $EDITOR->edit_file( $tmp->filename );
            }
            catch {
                my $error = $_[0];
                warn "$error";
                warn "*** There was an error editing ", $tmp->filename, "\n";
                while ( 1 ) {
                    print STDERR "Do you want to (c)ontinue, (a)bort, or (s)ave? ";
                    my $input = <STDIN>;
                    chomp $input;
                    die $error unless defined $input;
                    if ( 0 ) { }
                    elsif ( $input eq 'c' ) {
                        last;
                    }
                    elsif ( $input eq 'a' ) {
                        die $error;
                    }
                    elsif ( $input eq 's' ) {
                        my $save;
                        unless ( $save = File::Temp->new( dir => '.', template => 'PintoEditor.XXXXXX', unlink => 0 ) ) {
                            warn "Unable to create temporary file: $!" and next;
                        }
                        my $tmp_filename = $tmp->filename;
                        my $tmpr;
                        unless ( $tmpr = IO::File->new( $tmp_filename, 'r' ) ) {
                            warn "Unable to open ($tmp_filename): $!" and next;
                        }
                        $save->print( join '', <$tmpr> );
                        $save->close;
                        warn "Saved to: ", $save->filename, " ", ( -s $save->filename ), "\n";
                    }
                    else {
                        warn "I don't understand ($input)\n";
                    }
                }

            };
        }

        my $document;
        {
            my $filename = $tmp->filename;
            my $tmpr = IO::File->new( $filename, 'r' ) or die "Unable to open ($filename): $!";
            $document = join '', <$tmpr>;
            $tmpr->close;
            undef $tmpr;
        }

        $self->document( $document );
        my ( $preamble, $content ) = $self->split( $document );
        $self->preamble( $preamble );
        $self->content( $content );

        if ( my $process = $self->process ) {
            my ( @result, $retry );
            try {
                @result = $process->( $self );
            }
            catch {
                die $_ unless $_ eq $RETRY;
                $retry = 1;
            };

            next if $retry;

            return $result[0] if defined $result[0];
        }

        return $content;
    }

}

#-----------------------------------------------------------------------------

sub first_line_blank {
    my $self = shift;
    return $self->document =~ m/\A\s*$/m;
}

#-----------------------------------------------------------------------------

sub line0_blank { return $_[0]->first_line_blank }

#-----------------------------------------------------------------------------

sub preamble_from_initial {
    my $self = shift;
    my @preamble;
    for my $part ( "$_[0]", $self->initial_preamble ) {
        next unless defined $part;
        chomp $part;
        push @preamble, $part;
    }
    $self->preamble( join "\n", @preamble, '' ) if @preamble;
}

#-----------------------------------------------------------------------------

sub retry {
    my $self = shift;
    die $RETRY;
}

#-----------------------------------------------------------------------------

sub split {
    my $self = shift;
    my $document = shift;

    return ( undef, $document ) unless my $separator = $self->separator;

    die "Invalid separator ($separator)" if ref $separator;

    if ( my $mark = Text::Clip->new( data => $document )->find( qr/^\s*$separator\s*$/m ) ) {
        return ( $mark->preceding, $mark->remaining );
    }

    return ( undef, $document );
}

#-----------------------------------------------------------------------------

sub join {
    my $self = shift;
    my $preamble = shift;
    my $content = shift;

    return $content unless defined $preamble;
    chomp $preamble;

    my $separator = $self->separator;
    unless ( defined $separator ) {
        return $content unless length $preamble;
        return join "\n", $preamble, $content;
    }
    return join "\n", $separator, $content unless length $preamble;
    return join "\n", $preamble, $separator, $content;
}

#-----------------------------------------------------------------------------
1;

__END__

#-----------------------------------------------------------------------------

=pod

=head1 DESCRIPTION

This is a forked version of L<Term::EditorEdit::Edit> which does not use the deprecated
module L<Any::Moose>. My thanks to Robert Krimen for authoring the original.
No user-servicable parts in here.

=cut
