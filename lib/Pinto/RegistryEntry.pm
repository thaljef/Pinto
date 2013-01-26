# ABSTRACT: A record in the stack registry

package Pinto::RegistryEntry;

use Moose;
use MooseX::Aliases;
use MooseX::Types::Moose qw(Str Bool Int);

use String::Format;

use Pinto::Types qw(Vers);
use Pinto::Util qw(itis author_dir);
use Pinto::Exception qw(throw);

use overload ( '""' => 'to_string' );

#------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------


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


has author => (
    is        => 'rw',
    isa       => Str,
    required  => 1,
);


has archive => (
    is        => 'rw',
    isa       => Str,
    required  => 1,
);


has is_pinned => (
    is        => 'rw',
    isa       => Bool,
    default   => 0,
);

has distribution => (
   is         => 'ro',
   isa        => Str,
   alias      => 'path',
   default    =>  sub { join '/', author_dir($_[0]->author), $_[0]->archive },
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
    my ($package, $version, $author_archive, $is_pinned) = split m/\s+/, $str;
    my ($author, $archive) = split m|/|, $author_archive; 

    return { package      => $package, 
             version      => $version, 
             author       => $author,
             archive      => $archive, 
             is_pinned    => $is_pinned };

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
         'A' => sub { $self->author         },
         'p' => sub { $self->package        },
         'v' => sub { $self->version        },
         'h' => sub { $self->path           },
         'f' => sub { $self->archive        },
         'i' => sub { $self->is_pinned      },
    );

    # Some attributes are just undefined, usually because of
    # oddly named distributions and other old stuff on CPAN.
    no warnings 'uninitialized';  ## no critic qw(NoWarnings);

    $format ||= $self->default_format;
    return String::Format::stringf($format, %fspec);
}


#-------------------------------------------------------------------------------

sub default_format {
    my ($self) = @_;

    return '%A/%f/%p~%v';
}

#-----------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#-----------------------------------------------------------------------------
1;

