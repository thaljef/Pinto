# ABSTRACT: Install packages from the repository

package Pinto::Action::Install;

use Moose;
use MooseX::Types::Moose qw(Bool HashRef ArrayRef Maybe Str);
use MooseX::MarkAsMethods (autoclean => 1);

use File::Which qw(which);

use Pinto::Types qw(StackName StackDefault StackObject);
use Pinto::Exception qw(throw);
use Pinto::SpecFactory;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

extends qw( Pinto::Action );

#------------------------------------------------------------------------------

with qw( Pinto::Role::Committable );

#------------------------------------------------------------------------------

has cpanm_options => (
    is      => 'ro',
    isa     => HashRef[Maybe[Str]],
    default => sub { {} },
    lazy    => 1,
);


has cpanm_exe => (
    is      => 'ro',
    isa     => Str,
    default => sub { which('cpanm') || throw 'Could not find cpanm in PATH' },
    lazy    => 1,
);


has stack   => (
    is        => 'ro',
    isa       => StackName | StackDefault | StackObject,
    default   => undef,
);


has targets => (
    isa      => ArrayRef[Str],
    traits   => [ 'Array' ],
    handles  => { targets => 'elements' },
    required => 1,
);


has pull => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);

#------------------------------------------------------------------------------

sub BUILD {
    my ($self) = @_;

    my $cpanm_exe = $self->cpanm_exe;

    my $cpanm_version_cmd = "$cpanm_exe --version";
    my $cpanm_version_cmd_output = qx{$cpanm_version_cmd};  ## no critic qw(Backtick)
    throw "Could not learn version of cpanm: $!" if $?;

    my ($cpanm_version) = $cpanm_version_cmd_output =~ m{version ([\d.]+)}
      or throw "Could not parse cpanm version number from $cpanm_version_cmd_output";

    my $min_cpanm_version = '1.5013';
    if ($cpanm_version < $min_cpanm_version) {
      throw "Your cpanm ($cpanm_version) is too old. Must have $min_cpanm_version or newer";
    }

    return $self;
}

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    my $stack = $self->repo->get_stack($self->stack);

    if ($self->pull) {

        my $old_head = $stack->head;
        my $new_head = $stack->start_revision;

        my @pulled_dists = map { $self->_pull($stack, $_) } $self->targets; 

        if ($stack->has_changed and not $self->dry_run) {
            $self->generate_message_title('Pulled', @pulled_dists);
            $self->generate_message_details($stack, $old_head, $new_head);
            $stack->commit_revision(message => $self->edit_message);
            $self->result->changed;
        }
    }

    $self->_install($stack, $self->targets);

    return $self->result;
 }

#------------------------------------------------------------------------------

sub _pull {
    my ($self, $stack, $target) = @_;

    if (-d $target or -f $target) {
        $self->info("Target $target is a file or directory.  Won't pull it");
        return $self;
    }

    $target = Pinto::SpecFactory->make_spec($target);

    my $dist =         $stack->get_distribution(spec => $target)
               || $self->repo->get_distribution(spec => $target)
               || $self->repo->ups_distribution(spec => $target);


    $dist->register(stack => $stack);
    $self->repo->pull_prerequisites(dist => $dist, stack => $stack);

    return $dist;
}

#------------------------------------------------------------------------------

sub _install {
    my ($self, $stack, @targets) = @_;

    # Wire cpanm to our repo
    my $opts = $self->cpanm_options;
    $opts->{'mirror-only'} = '';
    $opts->{mirror} = 'file://' . $self->repo->root->absolute . "/$stack";

    # Process other cpanm options
    my @cpanm_opts;
    for my $opt ( keys %{ $opts } ){
        my $dashes = (length $opt == 1) ? '-' : '--';
        my $dashed_opt = $dashes . $opt;
        my $opt_value = $opts->{$opt};
        push @cpanm_opts, $dashed_opt;
        push @cpanm_opts, $opt_value if defined $opt_value && length $opt_value;
    }

    # Run cpanm
    $self->debug(join ' ', 'Running:', $self->cpanm_exe, @cpanm_opts);
    0 == system($self->cpanm_exe, @cpanm_opts, @targets)
      or throw "Installation failed.  See the cpanm build log for details";

    return $self;
}

#------------------------------------------------------------------------------

sub message_title {
    my ($self) = @_;

    my $targets  = join ', ', $self->targets;
    return "Pulled ${targets}.";
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#-----------------------------------------------------------------------------
1;

__END__
