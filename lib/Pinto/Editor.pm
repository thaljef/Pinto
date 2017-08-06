# ABSTRACT: Utility class for authoring commit messages

package Pinto::Editor;

use Moose;
use File::Temp;
use Pinto::Editor::Edit;

#-----------------------------------------------------------------------------

# VERSION

#-----------------------------------------------------------------------------

sub EDITOR {
    return $ENV{VISUAL} || $ENV{EDITOR};
}

#-----------------------------------------------------------------------------

our $__singleton__;
sub __singleton__ {
    return $__singleton__ ||=__PACKAGE__->new;
}

#-----------------------------------------------------------------------------

sub edit_file {
    my $self = shift;
    my $file = shift;
    die "*** Missing editor (No \$VISUAL or \$EDITOR)\n" unless my $editor = $self->EDITOR;
    my $rc = system $editor, $file;
    unless ( $rc == 0 ) {
        my ($exit_value, $signal, $core_dump);
        $exit_value = $? >> 8;
        $signal = $? & 127;
        $core_dump = $? & 128;
        die "Error during edit ($editor): exit value($exit_value), signal($signal), core_dump($core_dump): $!";
    }
}

#-----------------------------------------------------------------------------

sub edit {
    my $self = shift;
    $self = $self->__singleton__ unless blessed $self;
    my %given = @_;

    my $document = delete $given{document};
    $document = '' unless defined $document;

    my $file = delete $given{file};
    $file = $self->tmp unless defined $file;

    my $edit = Pinto::Editor::Edit->new(
        editor => $self,
        file => $file,
        document => $document,
        %given, # process, split, ...
    );

    return $edit->edit;
}

#-----------------------------------------------------------------------------

sub tmp { return File::Temp->new( unlink => 1 ) }

#-----------------------------------------------------------------------------
1;

__END__

#-----------------------------------------------------------------------------

=pod

=head1 DESCRIPTION

This is a forked version of L<Term::EditorEdit> which does not use the deprecated
module L<Any::Moose>. My thanks to Robert Krimen for authoring the original.
No user-servicable parts in here.

=cut
