package Pinto::Distribution;

# ABSTRACT: Represents a Perl distribution

use Moose;
use MooseX::Types::Moose qw(Str);
use Moose::Autobox;

use URI;
use Dist::Metadata 0.920; # supports .zip
use CPAN::DistnameInfo;
use Path::Class qw();

use Pinto::Util;
use Pinto::Package;
use Pinto::Types 0.017 qw(AuthorID File);
use Pinto::Exception::Args qw(throw_args);
use Pinto::Exception::IO qw(throw_io);

use overload ('""' => 'to_string');

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

has location => (
    is         => 'ro',
    isa        => Str,
    required   => 1,
);

has author   => (
    is         => 'ro',
    isa        => AuthorID,
    coerce     => 1,
    lazy_build => 1,
);

has packages => (
    is         => 'ro',
    traits     => [ 'Array' ],
    isa        => 'ArrayRef[Pinto::Package]',
    default    => sub { [] },
    init_arg   => undef,
    handles    => {add_packages => 'push'},
    auto_deref => 1,
);

has _info => (
    is         => 'ro',
    isa        => 'CPAN::DistnameInfo',
    init_arg   => undef,
    lazy_build => 1,
    handles    => {
        name       => 'dist',
        version    => 'version',
    },
);

has _path => (
    is         => 'ro',
    isa        => File,
    init_arg   => undef,
    lazy_build => 1,
);

#------------------------------------------------------------------------------

sub _build__info {
    my ($self) = @_;

    return CPAN::DistnameInfo->new($self->location);
}

sub _build__path {
    my ($self) = @_;

    return Path::Class::file( split '/', $self->location() );
}

sub _build_author {
    my ($self) = @_;

    return $self->_info->cpanid();
}

#------------------------------------------------------------------------------

sub path {
    my ($self, @base) = @_;

    return Path::Class::file(@base, qw(authors id), $self->_path());
}

#------------------------------------------------------------------------------

sub url {
    my ($self, $base) = @_;

    return URI->new( "$base/authors/id/" . $self->location() )->canonical();
}

#------------------------------------------------------------------------------

sub package_count {
    my ($self) = @_;

    return $self->packages->length();
}

#------------------------------------------------------------------------------

sub new_from_file {
    my ($class, %args) = @_;

    my $file = $args{file}
        or throw_args 'Must specify a file';

    my $author = $args{author}
        or throw_args 'Must specify an author';

    $file = Path::Class::file($file)
        if not eval {$file->isa('Path::Class::File')};

    throw_io "$file does not exist"  if not -e $file;
    throw_io "$file is not readable" if not -r $file;
    throw_io "$file is not a file"   if not -f $file;

    my $basename = $file->basename();
    my $author_dir = Pinto::Util::author_dir($author);

    my $location = $author_dir->file($basename)->as_foreign('Unix');
    my $self = $class->new(location => $location->stringify());
    $self->_extract_packages(file => $file);

    return $self;
}

#------------------------------------------------------------------------------

sub _extract_packages {
    my ($self, %args) = @_;

    my $file = $args{file};

    my $distmeta = Dist::Metadata->new(file => $file->stringify());
    my $provides = $distmeta->package_versions();
    throw_io "$file contains no packages" if not %{ $provides };

    my @packages = ();
    for my $package_name (sort keys %{ $provides }) {

        my $version = $provides->{$package_name} || 'undef';
        push @packages, Pinto::Package->new( name    => $package_name,
                                             dist    => $self,
                                             version => $version );
    }

    $self->add_packages(@packages);
    return $self;
}

#------------------------------------------------------------------------------

sub to_string {
    my ($self) = @_;
    return $self->location();
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#------------------------------------------------------------------------------
1;

__END__
