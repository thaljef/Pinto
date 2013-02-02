# ABSTRACT: Associates packages with a stack

package Pinto::Registry;

use Moose;
use MooseX::Types::Moose qw(HashRef Bool);
use MooseX::MarkAsMethods (autoclean => 1);

use Pinto::Util qw(itis);
use Pinto::Types qw(File);
use Pinto::Exception qw(throw);
use Pinto::RegistryEntry;

#------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------

has file => (
    is         => 'ro',
    isa        => File,
    required   => 1,
);

has repo => (
    is         => 'ro',
    isa        => 'Pinto::Repository',
    weak_ref   => 1,
    required   => 1,
);

has entries_by_distribution => (
    is        => 'ro',
    isa       => HashRef,
    default   => sub { {} },
);


has entries_by_package => (
    is        => 'ro',
    isa       => HashRef,
    default   => sub { {} },
);


has has_changed => (
    is          => 'ro',
    isa         => Bool,
    writer      => '_set_has_changed',
    default     => 0,
    init_arg    => undef,
);

#------------------------------------------------------------------------------

with qw(Pinto::Role::Loggable);

#------------------------------------------------------------------------------

sub BUILD {
    my ($self) = @_;

    my $file = $self->file;
    return $self if not -e $file;

    open my $fh, '<', $file or throw "Failed to open index file $file: $!";

    while (<$fh>) {
      my $entry = Pinto::RegistryEntry->new($_);
      $self->add(entry => $entry);
    }

    close $fh;

    # Additions do not count as changes during
    # construction, so reset the has_changed flag.
    $self->_set_has_changed(0);

    return $self;
}

#------------------------------------------------------------------------

sub add {
  my ($self, %args) = @_;

  my $entry = $args{entry};
  my $pkg   = $entry->package;
  my $dist  = $entry->distribution;

  $self->entries_by_distribution->{$dist}->{$pkg} = $entry;
  $self->entries_by_package->{$pkg} = $entry;

  $self->_set_has_changed(1);

  $self;

}

#------------------------------------------------------------------------

sub delete {
  my ($self, %args) = @_;

  my $entry = $args{entry};
  my $pkg   = $entry->package;
  my $dist  = $entry->distribution;

  delete $self->entries_by_package->{$pkg};
  delete $self->entries_by_distribution->{$dist}->{$pkg};

  my %remaining_pkgs = %{ $self->entries_by_distribution->{$dist} };
  delete $self->entries_by_distribution->{$dist} if not %remaining_pkgs;

  $self->_set_has_changed(1);

  return $self;
}

#------------------------------------------------------------------------

sub entries {
    my ($self) = @_;

    my @keys = sort keys %{ $self->entries_by_package };

    return [ @{$self->entries_by_package}{@keys} ]; # Slicing!
}

#------------------------------------------------------------------------

sub distribution_count {
  my ($self) = @_;

  return scalar keys %{ $self->entries_by_distribution };
}

#------------------------------------------------------------------------

sub package_count {
  my ($self) = @_;

  return scalar keys %{ $self->entries_by_package };
}

#------------------------------------------------------------------------

sub lookup {
  my ($self, %args) = @_;

  if (my $pkg = $args{package}) {
    my $name = itis($pkg, 'Pinto::Schema::Result::Package') ? $pkg->name : "$pkg";
    return $self->entries_by_package->{$name};
  }
  elsif (my $dist = $args{distribution}) {
    my $path = itis($dist, 'Pinto::Schema::Result::Distribution') ? $dist->path : "$dist";
    return $self->entries_by_distribution->{$path};
  }
  else {
    throw "Don't know what to do"
  }
}

#------------------------------------------------------------------------

sub register {
  my ($self, %args) = @_;

  return $self->register_distribution(%args) if $args{distribution};
  return $self->register_package(%args)      if $args{package};

  throw "Don't know what to do with %args";

}

#------------------------------------------------------------------------
sub register_distribution {
  my ($self, %args) = @_;

  my $dist  = $args{distribution};
  my $force = $args{force};
  my $pin   = $args{pin};

  my $errors = 0;
    for my $new_pkg ($dist->packages) {

      my $pkg_name  = $new_pkg->name;
      my $old_entry = $self->lookup(package => $pkg_name);

      if (not defined $old_entry) {
          $self->debug(sub {"Registering $new_pkg on stack"} );
          $self->register_package(package => $new_pkg, pin => $pin);
          next;
      }

      my $old_pkg = $self->repo->get_package( name => $pkg_name,
                                              path => $old_entry->distribution );

      if ($new_pkg == $old_pkg) {
        $self->debug( sub {"Package $old_pkg is already on stack"} );
        $old_entry->pin && $self->_set_has_changed(1) if $pin and not $old_entry->is_pinned;
        next;
      }


      if ($old_entry->is_pinned) {
        $self->error("Cannot add $new_pkg to stack because $pkg_name is pinned to $old_pkg");
        $errors++;
        next;
      }

      my ($log_as, $direction) = ($new_pkg < $old_pkg) ? ('warning', 'Downgrading')
                                                       : ('notice',  'Upgrading');

      $self->delete(entry => $old_entry);
      $self->$log_as("$direction package $old_pkg to $new_pkg");
      $self->register_package(package => $new_pkg, pin => $pin);
    }

    throw "Unable to register distribution $dist on stack" if $errors;

    return $self;

}

#------------------------------------------------------------------------

sub register_package {
  my ($self, %args) = @_;

  my $pkg = $args{package};
  my $pin = $args{pin} || 0;

  my %struct = ( package   => $pkg->name,
                 version   => $pkg->version,
                 author    => $pkg->distribution->author,
                 archive   => $pkg->distribution->archive,
                 is_pinned => $pin );

  my $entry = Pinto::RegistryEntry->new(%struct);

  $self->add(entry => $entry);

  return $entry;
}

#------------------------------------------------------------------------

sub unregister {
  my ($self, %args) = @_;

  return $self->unregister_distribution(%args) if $args{distribution};
  return $self->unregister_package(%args)      if $args{package};

  throw "Don't know what to do with %args";

}
#------------------------------------------------------------------------

sub unregister_distribution {
  my ($self, %args) = @_;

  my $dist  = $args{distribution};
  my $force = $args{force};

  delete $self->entries_by_distribution->{ $dist->path }
    or throw "Distribution $dist is not registered on this stack";

  $self->unregister(package => $_) for $dist->packages;

  return $self;
}

#------------------------------------------------------------------------

sub unregister_package {
  my ($self, %args) = @_;

  my $pkg   = $args{package};
  my $force = $args{force};

  delete $self->entries_by_package->{ $pkg->name }
    or throw "Package $pkg is not registered on this stack";

  return $self;
}


#------------------------------------------------------------------------

sub pin {
    my ($self, %args) = @_;

    my $dist    = $args{distribution};
    my $entries = $self->lookup(%args);

    throw "Distribution $dist is not registered on this stack" if not defined $entries;

    for my $entry (values %{ $entries }) {
      next if $entry->is_pinned;
      $self->_set_has_changed(1);
      $entry->pin;
    }

    return $self
}

#------------------------------------------------------------------------

sub unpin {
    my ($self, %args) = @_;

    my $dist    = $args{distribution};
    my $entries = $self->lookup(%args);

    throw "Distribution $dist is not registered on this stack" if not defined $entries;

    for my $entry (values %{ $entries }) {
      next if not $entry->is_pinned;
      $self->_set_has_changed(1);
      $entry->unpin;
    }

    return $self
}

#------------------------------------------------------------------------

sub entry_count {
  my ($self) = @_;

  return scalar keys %{ $self->entries_by_package };
}

#------------------------------------------------------------------------

sub write {
  my ($self) = @_;

  my $format = "%-32p  %12v  %A/%f  %i\n";

  my $fh = $self->file->openw;
  print { $fh } $_->to_string($format) for @{ $self->entries };
  close $fh;

  return $self;
}

#------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------
1;
