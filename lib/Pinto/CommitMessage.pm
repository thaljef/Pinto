# ABSTRACT: Utility class for constructing commit messages

package Pinto::CommitMessage;

use Moose;
use MooseX::Types::Moose qw(ArrayRef Str);

use Term::EditorEdit;

use overload ( q{""} => 'to_string' );

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

has stacks => (
    traits  => [ qw(Array) ],
    isa     => ArrayRef[ 'Pinto::Schema::Result::Stack' ],
    handles => {stacks => 'elements'},
    default => sub { [] },
);


has title => (
    is      => 'ro',
    isa     => Str,
    default => '',
);


has details => (
    is      => 'ro',
    isa     => Str,
    builder => '_build_details',
    lazy    => 1,
);

#------------------------------------------------------------------------------

sub _build_details {
    my ($self) = @_;

    my @stacks = $self->stacks;

    return 'No details available.' if not @stacks;

    my $details = '';
    for my $stack ( @stacks ) {
        my @changes = $stack->head_revision->kommit->registration_changes;
        $details .= "# STACK: $stack\n" if @stacks > 1;
        $details .= "# $_\n" for (@changes ? @changes : '# No details available');
        $details .= "#\n#\n";
    }

    return $details;
}

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
# Change details follow:
#
$details
END_MESSAGE
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------
1;

__END__
