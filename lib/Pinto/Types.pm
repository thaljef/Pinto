# ABSTRACT: Moose types used within Pinto

package Pinto::Types;

use strict;
use warnings;
use version;

use MooseX::Types -declare => [ qw( AuthorID Username Uri Dir File FileList Io Version
                                    StackName StackAll StackDefault PropertyName PkgSpec
                                    PkgSpecList StackObject DistSpec DistSpecList
                                    Spec SpecList RevisionID RevisionHead) ];

use MooseX::Types::Moose qw( Str Num ScalarRef ArrayRef Undef
                             HashRef FileHandle Object Int );

use URI;
use Path::Class::Dir;
use Path::Class::File;
use IO::String;
use IO::Handle;
use IO::File;

use Pinto::SpecFactory;
use Pinto::Constants qw(:all);

#-----------------------------------------------------------------------------

# VERSION

#-----------------------------------------------------------------------------

subtype AuthorID,
  as Str,
  where   { $_ =~ $PINTO_AUTHOR_REGEX },
  message { 'The author id (' . (defined() ? $_ : 'undef') . ') must be alphanumeric' };

#-----------------------------------------------------------------------------

subtype Username,
  as Str,
  where   { $_ =~ $PINTO_USERNAME_REGEX },
  message { 'The username (' . (defined() ? $_ : 'undef') . ') must be alphanumeric' };

#-----------------------------------------------------------------------------

subtype StackName,
  as      Str,
  where   { $_ =~ $PINTO_STACK_NAME_REGEX },
  message { 'The stack name (' . (defined() ? $_ : 'undef') . ') must be alphanumeric' };

#-----------------------------------------------------------------------------

subtype StackAll,
  as      Str,
  where   { $_ eq $PINTO_STACK_NAME_ALL },
  message { qq{The stack name must be '$PINTO_STACK_NAME_ALL'} };

#-----------------------------------------------------------------------------

subtype StackDefault,
  as      Undef;

#-----------------------------------------------------------------------------

class_type StackObject, {class => 'Pinto::Schema::Result::Stack'};

#-----------------------------------------------------------------------------

subtype PropertyName,
  as      Str,
  where   { $_ =~ $PINTO_PROPERTY_NAME_REGEX },
  message { 'The property name (' . (defined() ? $_ : 'undef') . 'must be alphanumeric' };

#-----------------------------------------------------------------------------

class_type Version, {class => 'version'};

coerce Version,
  from Str,
  via { version->parse($_) };

coerce Version,
  from Num,
  via { version->parse($_) };

#-----------------------------------------------------------------------------

class_type Uri, {class => 'URI'};

coerce Uri,
  from Str,
  via { URI->new($_) };

#-----------------------------------------------------------------------------

class_type Dir, {class => 'Path::Class::Dir'};

coerce Dir,
  from Str,             via { Path::Class::Dir->new($_) },
  from ArrayRef,        via { Path::Class::Dir->new(@{$_}) };

#-----------------------------------------------------------------------------

class_type File, {class => 'Path::Class::File'};

coerce File,
  from Str,             via { Path::Class::File->new($_) },
  from ArrayRef,        via { Path::Class::File->new(@{$_}) };

#-----------------------------------------------------------------------------

subtype FileList, as ArrayRef[File];

coerce FileList,
  from File,          via { [ $_ ] },
  from Str,           via { [ Path::Class::File->new($_) ] },
  from ArrayRef[Str], via { [ map { Path::Class::File->new($_) } @$_ ] };

#-----------------------------------------------------------------------------

class_type PkgSpec, {class => 'Pinto::PackageSpec'};

coerce PkgSpec,
  from Str,     via { Pinto::SpecFactory->make_spec($_) },
  from HashRef, via { Pinto::SpecFactory->make_spec($_) };

#-----------------------------------------------------------------------------

class_type DistSpec, {class => 'Pinto::DistributionSpec'};

coerce DistSpec,
  from Str,         via { Pinto::SpecFactory->make_spec($_) },
  from HashRef,     via { Pinto::SpecFactory->make_spec($_) };


#-----------------------------------------------------------------------------

subtype SpecList,
  as ArrayRef[PkgSpec | DistSpec];    ## no critic qw(ProhibitBitwiseOperators);

coerce SpecList,
  from  PkgSpec,            via { [ $_ ] },
  from  DistSpec,           via { [ $_ ] },
  from  Str,                via { [ Pinto::SpecFactory->make_spec($_) ] },
  from  ArrayRef[Str],      via { [ map { Pinto::SpecFactory->make_spec($_) } @$_ ] };

#-----------------------------------------------------------------------------

subtype DistSpecList,
  as ArrayRef[DistSpec];    ## no critic qw(ProhibitBitwiseOperators);

coerce DistSpecList,
  from  DistSpec,           via { [ $_ ] },
  from  Str,                via { [ Pinto::DistributionSpec->new($_) ] },
  from  ArrayRef[Str],      via { [ map { Pinto::DistributionSpec->new($_) } @$_ ] };

#-----------------------------------------------------------------------------

subtype PkgSpecList,
  as ArrayRef[PkgSpec];    ## no critic qw(ProhibitBitwiseOperators);

coerce PkgSpecList,
  from  DistSpec,           via { [ $_ ] },
  from  Str,                via { [ Pinto::PackageSpec->new($_) ] },
  from  ArrayRef[Str],      via { [ map { Pinto::PackageSpec->new($_) } @$_ ] };

#-----------------------------------------------------------------------------

subtype Io, as Object;

coerce Io,
    from Str,        via { my $fh = IO::File->new(); $fh->open($_);   return $fh },
    from File,       via { my $fh = IO::File->new(); $fh->open("$_"); return $fh },
    from ArrayRef,   via { IO::Handle->new_from_fd( @$_ ) },
    from ScalarRef,  via { IO::String->new( ${$_} ) };

#-----------------------------------------------------------------------------

subtype RevisionID,
  as Str,
  where   { $_ =~ $PINTO_REVISION_ID_REGEX and length($_) >= 4 },
  message { 'The revision id (' . (defined() ? $_ : 'undef') . ') must be a hexadecimal string of 4 or more chars' };

coerce RevisionID,
    from Str,        via { lc $_ };

#-----------------------------------------------------------------------------

subtype RevisionHead, as Undef;

#-----------------------------------------------------------------------------


1;

__END__
