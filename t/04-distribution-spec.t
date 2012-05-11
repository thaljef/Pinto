#!perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

use Pinto::DistributionSpec;

#------------------------------------------------------------------------------
{

  my $spec = Pinto::DistributionSpec->new('AUTHOR/subdir/Foo-1.2.tar.gz');
  is $spec->author,   'AUTHOR',  'Parsed author from string';
  is $spec->archive, 'Foo-1.2.tar.gz',  'Parsed archive from string';
  is $spec->path, 'A/AU/AUTHOR/subdir/Foo-1.2.tar.gz',  'Constructed path from string';
  is "$spec", 'AUTHOR/subdir/Foo-1.2.tar.gz', 'Stringified object';

}

#------------------------------------------------------------------------------

{

  my $spec = Pinto::DistributionSpec->new('author/subdir/Foo-1.2.tar.gz');
  is $spec->author, 'AUTHOR',  'Parsed lowercase author from string';
  is $spec->archive, 'Foo-1.2.tar.gz',  'Parsed archive from string';
  is $spec->path, 'A/AU/AUTHOR/subdir/Foo-1.2.tar.gz',  'Constructed path from string';
  is "$spec", 'AUTHOR/subdir/Foo-1.2.tar.gz', 'Stringified object';

}

#------------------------------------------------------------------------------

{

  my $spec = Pinto::DistributionSpec->new(author => 'AUTHOR',
                                          subdirs => [qw(foo bar)],
                                          archive => 'Foo-1.2.tar.gz');

  is $spec->author, 'AUTHOR',  'author from attribute';
  is $spec->archive, 'Foo-1.2.tar.gz',  'archive from attribute';
  is $spec->path, 'A/AU/AUTHOR/foo/bar/Foo-1.2.tar.gz',  'Constructed path from string';
  is "$spec", 'AUTHOR/foo/bar/Foo-1.2.tar.gz', 'Stringified object';

}

#------------------------------------------------------------------------------

{

  throws_ok { Pinto::DistributionSpec->new('AUTHOR/') }
    qr{Invalid distribution spec},  'Invalid dist spec';

  throws_ok { Pinto::DistributionSpec->new('/Foo-1.2.tar.gz') }
    qr{Invalid distribution spec},  'Invalid dist spec';

  throws_ok { Pinto::DistributionSpec->new('Foo-1.2.tar.gz') }
    qr{Invalid distribution spec},  'Invalid dist spec';

  throws_ok { Pinto::DistributionSpec->new('') }
    qr{Invalid distribution spec},  'Empty dist spec';

}

#------------------------------------------------------------------------------

done_testing;
