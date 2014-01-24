package TestClass;

use Moose;

use Pinto::Types qw(
    ANSIColor
    ANSIColorSet
    AuthorID
    DiffStyle
    Dir
    DistributionTarget
    DistributionTargetList
    File
    Io
    PackageTarget
    PackageTargetList
    PropertyName
    RevisionID
    StackAll
    StackDefault
    StackName
    TargetList
    Uri
    Version
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
    isa    => PackageTarget,
    coerce => 1,
);

has pkgs => (
    is     => 'rw',
    isa    => PackageTargetList,
    coerce => 1,
);

has dist => (
    is     => 'rw',
    isa    => DistributionTarget,
    coerce => 1,
);

has dists => (
    is     => 'rw',
    isa    => DistributionTargetList,
    coerce => 1,
);

has targets => (
    is     => 'rw',
    isa    => TargetList,
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

has diffstyle => (
    is  => 'rw',
    isa => DiffStyle,
);

#-----------------------------------------------------------------------------

1;
