# ABSTRACT: Utility class for constructing commit messages

package Pinto::CommitMessage;

use Moose;
use MooseX::Types::Moose qw(Str);
use MooseX::MarkAsMethods (autoclean => 1);

use Term::EditorEdit;

use overload ( q{""} => 'to_string' );

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

has stack => (
    is       => 'ro',
    isa      => 'Pinto::Schema::Result::Stack',
    required => 1,
);


has title => (
    is      => 'ro',
    isa     => Str,
    default => '',
);


has details => (
    is      => 'ro',
    isa     => Str,
    default => '',
);

#------------------------------------------------------------------------------

sub edit {
    my ($self) = @_;

    my $message = Term::EditorEdit->edit(document => $self->to_string);
    $message =~ s/^ [#] .* $//gmsx;  # Strip comments

    return $message;
}

#------------------------------------------------------------------------------

sub to_string {
    my ($self) = @_;

    my $title   = $self->title;
    my $details = $self->details;

    return <<END_MESSAGE;
$title


#------------------------------------------------------------------------------
# Please edit or ammend the message above to describe the change.  The message
# should include a one-line title, followed by one blank line, followed by the
# message body.  Any line that starts with "#" will be ignored.  To abort the
# commit, delete the entire message above, save the file, and close the editor. 
#
# Changes to be committed:
#
$details
END_MESSAGE
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------
1;

__END__
