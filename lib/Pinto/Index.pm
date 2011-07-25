package Pinto::Index;

# ABSTRACT: Represents an 02packages.details.txt file

use Moose;
use Moose::Autobox;
use MooseX::Types::Path::Class;

use Carp;
use Compress::Zlib;
use Path::Class qw();

use Pinto::Package;

use overload ('+' => '__plus', '-' => '__minus');

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

has 'packages_by_name' => (
    is         => 'ro',
    isa        => 'HashRef',
    default    => sub { {} },
    init_arg   => undef,
    writer     => '_set_packages_by_name',
);

has 'packages_by_file' => (
    is         => 'ro',
    isa        => 'HashRef',
    default    => sub { {} },
    init_arg   => undef,
    writer     => '_set_packages_by_file',
);

has 'file' => (
    is       => 'ro',
    isa      => 'Path::Class::File',
    coerce   => 1,
);

#------------------------------------------------------------------------------

sub BUILD {
    my ($self) = @_;
    if (my $file = $self->file()){
        $self->read(file => $file);
    }
    return $self;
}

#------------------------------------------------------------------------------

sub read  {
    my ($self, %args) = @_;

    my $file = $args{file} || $self->file()
        or croak "This index has no file attribute, so you must specify one";

    $file = Path::Class::file($file) unless eval { $file->isa('Path::Class::File') };

    return if not -e $file;

    my $fh = $file->openr();
    my $gz = Compress::Zlib::gzopen($fh, "rb")
        or die "Cannot open $file: $Compress::Zlib::gzerrno";

    my $inheader = 1;
    while ($gz->gzreadline($_) > 0) {
        if ($inheader) {
            $inheader = 0 if not /\S/;
            next;
        }
        chomp;
        my ($n, $v, $f) = split;
        my $package = Pinto::Package->new(name => $n, version => $v, file => $f);
        $self->put($package);
    }

    return $self;
}

#------------------------------------------------------------------------------

sub write {
    my ($self, %args) = @_;

    # TODO: Accept a file handle argument

    my $file = $args{file} || $self->file()
        or croak 'This index has no file attribute, so you must specify one';

    $file = Path::Class::file($file) unless eval { $file->isa('Path::Class::File') };

    $file->dir()->mkpath(); # TODO: log & error check
    my $gz = Compress::Zlib::gzopen( $file->openw(), 'wb' );
    $self->_gz_write_header($gz);
    $self->_gz_write_packages($gz);
    $gz->gzclose();

    return $self;
}

#------------------------------------------------------------------------------

sub _gz_write_header {
    my ($self, $gz) = @_;

    my ($file, $url) = $self->file()
        ? ($self->file()->basename(), 'file://' . $self->file()->as_foreign('Unix') )
        : ('UNKNOWN', 'UNKNOWN');

    $gz->gzwrite( <<END_PACKAGE_HEADER );
File:         $file
URL:          $url
Description:  Package names found in directory \$CPAN/authors/id/
Columns:      package name, version, path
Intended-For: Automated fetch routines, namespace documentation.
Written-By:   Pinto::Index 0.01
Line-Count:   @{[ $self->package_count() ]}
Last-Updated: @{[ scalar localtime() ]}

END_PACKAGE_HEADER

    return $self;
}

#------------------------------------------------------------------------------

sub _gz_write_packages {
    my ($self, $gz) = @_;

    for my $package ( @{ $self->packages() } ) {
        $gz->gzwrite($package->to_string() . "\n");
    }

    return $self;
}

#------------------------------------------------------------------------------

sub merge {
    my ($self, @packages) = @_;

    # Maybe instead...
    # $self->remove($_) for @packages;
    # $self->put($_)    for @packages;

    for my $package (@packages) {
        $self->remove($package);
        $self->put($package);
    }

    return $self;
}

#------------------------------------------------------------------------------

sub add {
    my ($self, @packages) = @_;

    for my $package (@packages) {
        my $name = $package->name();
        my $author = $package->author();
        $self->put($package);
    }

    return $self;
}

#------------------------------------------------------------------------------

sub reload {
    my ($self) = @_;

    return $self->clear()->read();
}

#------------------------------------------------------------------------------

sub clear {
    my ($self) = @_;

    $self->_set_packages_by_name( {} );
    $self->_set_packages_by_file( {} );

    return $self;
}

#------------------------------------------------------------------------------


sub put {
    my ($self, @packages) = @_;

    for my $package (@packages) {
        $self->packages_by_name()->put($package->name(), $package);
        ($self->packages_by_file()->{$package->file()} ||= [])->push($package);
    }

    return $self;
}

#------------------------------------------------------------------------------

sub remove {
    my ($self, @packages) = @_;

    my @removed = ();
    for my $package (@packages) {

      my $name = eval { $package->name() } || $package;

      if (my $encumbent = $self->packages_by_name()->at($name)) {
          # Remove the file that contains the incumbent package and
          # then remove all packages that were contained in that file
          my $kin = $self->packages_by_file()->delete($encumbent->file());
          $self->packages_by_name()->delete($_) for map {$_->name()} @{$kin};
          push @removed, $encumbent->file();
      }

    }
    return @removed;
}

#------------------------------------------------------------------------------

sub package_count {
    my ($self) = @_;
    return $self->packages_by_name()->keys()->length();
}

#------------------------------------------------------------------------------

sub packages {
    my ($self) = @_;
    my $sorter = sub { $_[0]->name() cmp $_[1]->name() };
    return $self->packages_by_name()->values()->sort($sorter);
}

#------------------------------------------------------------------------------

sub files {
    my ($self) = @_;
    return $self->packages_by_file()->keys()->sort();
}

#------------------------------------------------------------------------------

sub files_native {
    my ($self, @base) = @_;
    my $mapper = sub { return Pinto::Util::native_file(@base, $_[0]) };
    return $self->files()->map($mapper);
}

#------------------------------------------------------------------------------

sub validate {
    my ($self) = @_;

    for my $package ( $self->packages_by_file()->values()->map( sub {@{$_[0]}} )->flatten() ) {
        my $name = $package->name();
        $self->packages_by_name->exists($name)
            or croak "Validation of package $name failed";
    }

    for my $package ( $self->packages_by_name()->values()->flatten() ) {
        my $file = $package->file();
        $self->packages_by_file->exists($file)
            or croak("Validation of file $file failed";
    }

    return $self;
}

#------------------------------------------------------------------------------

sub __plus {
    $DB::single = 1;
    my ($self, $other, $swap) = @_;
    ($self, $other) = ($other, $self) if $swap;
    my $class = ref $self;
    my $result = $class->new();
    $result->add( @{$self->packages()} );
    $result->merge( @{$other->packages()} );
    return $result;
}

#------------------------------------------------------------------------------

sub __minus {
    $DB::single = 1;
    my ($self, $other, $swap) = @_;
    ($self, $other) = ($other, $self) if $swap;
    my $class = ref $self;
    my $result = $class->new();
    $result->add( @{$self->packages()} );
    $result->remove( @{$other->packages()} );
    return $result;
}

#------------------------------------------------------------------------------

1;

__END__
