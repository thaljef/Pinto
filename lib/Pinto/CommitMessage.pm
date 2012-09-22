# ABSTRACT: Utility class for constructing commit messages

package Pinto::CommitMessage;

use Moose;
use MooseX::Types::Moose qw(ArrayRef Str);

use Term::EditorEdit;
use Text::Wrap qw(wrap);

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


has primer => (
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

    return 'No details available' if not @stacks;

    my $details = '';
    for my $stack ( @stacks ) {
        $details .= "STACK: $stack\n" if @stacks > 1;
        $details .= $stack->head_revision->change_details;
        $details.= "\n\n";
    }

    return $details;
}

#------------------------------------------------------------------------------

sub edit {
    my ($self) = @_;

    my $message = Term::EditorEdit->edit(document => $self->to_string);
    $message =~ s/( \n+ -{60,} \n .*)//smx;  # Strip details

    return $message;
}

#------------------------------------------------------------------------------

sub to_string {
    my ($self) = @_;

    local $Text::Wrap::columns = 80;
    my $primer  = wrap(undef, undef, $self->primer);
    my $details = $self->details;

    return <<END_MESSAGE;
$primer

------------------------------------------------------------------------------
Please replace or edit the message above to describe the change.  It is more
helpful to explain *why* the change happened, rather than *what* happened.
Details of the change follow:

$details
END_MESSAGE
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------
1;

__END__
