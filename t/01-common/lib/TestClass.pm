package TestClass;

use Moose;

use Pinto::Types qw(
    File
    Dir
    Uri
    Io
    AuthorID
    Version
    PropertyName
    StackName
    StackAll
    StackDefault
    PkgSpec
    PkgSpecList
    DistSpec
    DistSpecList
    SpecList
    RevisionID
    ANSIColor
    ANSIColorSet
);

#-----------------------------------------------------------------------------

has file => (
    is     => 'rw',
    isa    => File,
    coerce => 1,
);

has dir => (
    is     => 'rw',
    isa    => Dir,
    coerce => 1,
);

has uri => (
    is     => 'rw',
    isa    => Uri,
    coerce => 1,
);

has io => (
    is     => 'rw',
    isa    => Io,
    coerce => 1,
);

has author => (
    is     => 'rw',
    isa    => AuthorID,
    coerce => 1,
);

has stack => (
    is  => 'rw',
    isa => StackName,
);

has stack_all => (
    is  => 'rw',
    isa => StackAll,
);

has stack_default => (
    is  => 'rw',
    isa => StackDefault,
);

has property => (
    is  => 'rw',
    isa => PropertyName,
);

has version => (
    is     => 'rw',
    isa    => Version,
    coerce => 1,
);

has pkg => (
    is     => 'rw',
    isa    => PkgSpec,
    coerce => 1,
);

has pkgs => (
    is     => 'rw',
    isa    => PkgSpecList,
    coerce => 1,
);

has dist => (
    is     => 'rw',
    isa    => DistSpec,
    coerce => 1,
);

has dists => (
    is     => 'rw',
    isa    => DistSpecList,
    coerce => 1,
);

has targets => (
    is     => 'rw',
    isa    => SpecList,
    coerce => 1,
);

has revision => (
    is     => 'rw',
    isa    => RevisionID,
    coerce => 1,
);

has color => (
    is  => 'rw',
    isa => ANSIColor,
);

has colorset => (
    is  => 'rw',
    isa => ANSIColorSet,
);

#-----------------------------------------------------------------------------

1;
