# ABSTRACT: A record in the stack registry

package Pinto::RegistryEntry;

use Moose;
use MooseX::Aliases;
use MooseX::Types::Moose qw(Str Bool Int);

use String::Format;

use Pinto::Types qw(Vers);
use Pinto::Util qw(itis parse_dist_path);
use Pinto::Exception qw(throw);

use overload ( '""' => 'to_string' );

#------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------

has distribution => (
   is         => 'ro',
   isa        => Str,
   alias      => 'path',
   required   => 1,
);


has package => (
   is         => 'ro',
   isa        => Str,
   alias      => 'name',
   required   => 1,
);


has version => (
    is         => 'ro',
    isa        => Vers,
    coerce     => 1,
    required   => 1,
);


has is_pinned => (
    is        => 'rw',
    isa       => Bool,
    default   => 0,
);


has author => (
    is        => 'rw',
    isa       => Str,
    default   => sub { ( parse_dist_path($_[0]->path) )[0] },
    lazy      => 1,
);


has archive => (
    is        => 'rw',
    isa       => Str,
    default   => sub { ( parse_dist_path($_[0]->path) )[1] },
    lazy      => 1,
);

#------------------------------------------------------------------------------

override BUILDARGS => sub {
  my ($class, @args) = @_;

  return super( @args ) if @args > 1; 
  return $class->BUILDARGS_from_string(@args) if not ref $args[0];
  return $class->BUILDARGS_from_obj(@args) if itis($args[0], 'Pinto::Schema::Result::Package');

  throw "Don't now how to build from @args";
};

#------------------------------------------------------------------------

sub BUILDARGS_from_string {
  my ($class, $str) = @_;

    chomp $str;
    my ($package, $version, $path, $is_pinned, $mtime) = split /\s+/, $str;

    return { name         => $package, 
             version      => $version, 
             distribution => $path, 
             is_pinned    => $is_pinned,
             mtime        => $mtime };

}

#------------------------------------------------------------------------

sub BUILDARGS_from_package_object {
  my ($clas, $obj) = @_;

  return { name         => $obj->name,
           version      => $obj->version,
           distribution => $obj->path,
           mtime        => $obj->mtime, };
}

#------------------------------------------------------------------------

sub pin {
  my ($self) = @_;
  $self->is_pinned(1);
  return $self;
}

#------------------------------------------------------------------------

sub unpin {
  my ($self) = @_;
  $self->is_pinned(0);
  return $self;
}

#------------------------------------------------------------------------

sub to_string {
    my ($self, $format) = @_;

    my %fspec = (
         'p' => sub { $self->name               },
         'v' => sub { $self->version            },
         'h' => sub { $self->distribution       },
         'i' => sub { $self->is_pinned          },
    );

    # Some attributes are just undefined, usually because of
    # oddly named distributions and other old stuff on CPAN.
    no warnings 'uninitialized';  ## no critic qw(NoWarnings);

    $format ||= $self->default_format();
    return String::Format::stringf($format, %fspec);
}


#-------------------------------------------------------------------------------

sub default_format {
    my ($self) = @_;

    return "%-24p %12v %-48h %i";
}

#-----------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#-----------------------------------------------------------------------------
1;

