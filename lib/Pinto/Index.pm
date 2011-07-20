package Pinto::Index;

use Moose;
use Moose::Autobox;
use MooseX::Types::Path::Class;

use Carp;
use Compress::Zlib;
use Path::Class;

use Pinto::Package;

use overload ('+' => '__plus', '-' => '__minus');

#------------------------------------------------------------------------------

has 'packages_by_name' => (
    is         => 'ro',
    isa        => 'HashRef',
    default    => sub { {} },
    init_arg   => undef,
);

has 'packages_by_file' => (
    is         => 'ro',
    isa        => 'HashRef',
    default    => sub { {} },
    init_arg   => undef,
);

has 'source' => (
    is       => 'ro',
    isa      => 'Path::Class::File',
    coerce   => 1,
);

#------------------------------------------------------------------------------

sub BUILD {
    my ($self) = @_;
    if (my $source = $self->source()){
        $self->read(file => $source);
    }
    return $self;
}

#------------------------------------------------------------------------------


sub read  {
    my ($self, %args) = @_;
    my $file = $args{file} || $self->source()
        or croak "This index has no source, so you must specify a file";

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
    my ($self) = @_;

    my $source = $self->source();
    $source->dir()->mkpath(); # TODO: log & error check
    my $gz = Compress::Zlib::gzopen( $source->openw(), 'wb' );
    $self->_gz_write_header($gz);
    $self->_gz_write_packages($gz);
    $gz->gzclose();

    return $self;
}

#------------------------------------------------------------------------------

sub _gz_write_header {
    my ($self, $gz) = @_;

    $gz->gzwrite( <<END_PACKAGE_HEADER );
File:         @{[ $self->source()->basename() ]}
URL:          file://@{[ $self->source() ]}
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

        if ( my $incumbent = $self->packages_by_name()->at($name) ) {
            my $incumbent_author = $incumbent->author();
            croak "Package '$name' is already owned by '$incumbent_author'"
                if $incumbent_author ne $author;
        }

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

    $self->{packages_by_file} = {};
    $self->{packages_by_name}= {};

    return $self;
}

#------------------------------------------------------------------------------

sub put {
    my ($self, @packages) = @_;

    for my $package (@packages) {
        my $name = $package->name();
        my $file = $package->file();

        $self->packages_by_name()->put($name, $package);
        ($self->packages_by_file()->{$file} ||= [])->push($package);
    }
    return $self;
}

#------------------------------------------------------------------------------

sub remove {
    my ($self, @packages) = @_;

    for my $package (@packages) {

      my $name = eval { $package->name() } || $package;

      if (my $encumbent = $self->packages_by_name()->at($name)) {
          # Remove the file that contains the incumbent package and
          # then remove all packages that were contained in that file
          my $kin = $self->packages_by_file()->delete($encumbent->file());
          $self->packages_by_name()->delete($_) for map {$_->name()} @{$kin};
      }

    }
    return $self;
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

sub validate {
    my ($self) = @_;

    for my $package ( $self->packages_by_file()->values()->map( sub {@{$_[0]}} )->flatten() ) {
      $self->packages_by_name->exists($package->name()) or die "Shit!";
    }

    for my $package ( $self->packages_by_name()->values()->flatten() ) {
      $self->packages_by_file->exists($package->file()) or die 'Shit!';
    }
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
