package App::Pinto::Admin::Command::list;

# ABSTRACT: list the contents of the repository

use strict;
use warnings;

use Readonly;
use List::MoreUtils qw(none);

#-----------------------------------------------------------------------------

use base 'App::Pinto::Admin::Command';

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

Readonly my @LIST_TYPES => qw(local foreign conflicts all);
Readonly my $LIST_TYPES_STRING => join ' | ', sort @LIST_TYPES;
Readonly my $DEFAULT_LIST_TYPE => 'all';

#------------------------------------------------------------------------------

sub opt_spec {

    return (
        [ 'type=s'  => "One of: ( $LIST_TYPES_STRING )"],
    );
}

#------------------------------------------------------------------------------

sub validate_args {
    my ($self, $opts, $args) = @_;

    $self->usage_error('Arguments are not allowed') if @{ $args };

    $opts->{type} ||= $DEFAULT_LIST_TYPE;
    $self->usage_error('Invalid type') if none { $opts->{type} eq $_ } @LIST_TYPES;

    return 1;
}

#------------------------------------------------------------------------------

sub execute {
    my ($self, $opts, $args) = @_;

    $self->pinto->new_action_batch( %{$opts} );
    my $list_class = 'List::' . ucfirst $opts->{type};
    $self->pinto->add_action($list_class, %{$opts});
    my $result = $self->pinto->run_actions();
    return $result->is_success() ? 0 : 1;

}

#------------------------------------------------------------------------------

1;

__END__
