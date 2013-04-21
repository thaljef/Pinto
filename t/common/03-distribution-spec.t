#!perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

use Pinto::DistributionSpec;

#------------------------------------------------------------------------------

{

  my $spec = Pinto::DistributionSpec->new('Author/subdir/Foo-1.2.tar.gz');
  is $spec->author,   'Author',  'Parsed author from string';
  is $spec->author_canonical,   'AUTHOR',  'Canonical author is UPPERCASE';
  is $spec->archive, 'Foo-1.2.tar.gz',  'Parsed archive from string';
  is $spec->path, 'A/AU/AUTHOR/subdir/Foo-1.2.tar.gz',  'Constructed path from string';
  is "$spec", 'Author/subdir/Foo-1.2.tar.gz', 'Stringified object';

}

#------------------------------------------------------------------------------

{

  my $spec = Pinto::DistributionSpec->new(author => 'Author',
                                          subdirs => [qw(foo bar)],
                                          archive => 'Foo-1.2.tar.gz');

  is $spec->author, 'Author',  'author from attribute';
  is $spec->author_canonical,   'AUTHOR',  'Canonical author is UPPERCASE';
  is $spec->archive, 'Foo-1.2.tar.gz',  'archive from attribute';
  is $spec->path, 'A/AU/AUTHOR/foo/bar/Foo-1.2.tar.gz',  'Constructed path from string';
  is "$spec", 'Author/foo/bar/Foo-1.2.tar.gz', 'Stringified object';

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
