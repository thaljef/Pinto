#!perl

use Test::More;
use Pinto::Tester;
use Pinto::Tester::Util qw(make_dist_struct parse_reg_spec);

#-------------------------------------------------------------------------------

{
  my $spec = 'AUTHOR/FooAndBar-1.2=Foo~1.2,Bar~0.0&Baz~3.1,Nuts~2.4';
  my $struct = make_dist_struct($spec);
  is $struct->{cpan_author}, 'AUTHOR', 'Got author';
  is $struct->{name}, 'FooAndBar', 'Got name';
  is_deeply $struct->{provides}->{Foo}, {file => 'lib/Foo.pm', version => '1.2'};
  is_deeply $struct->{provides}->{Bar}, {file => 'lib/Bar.pm', version => '0.0'};
  is_deeply $struct->{requires}, {Baz => '3.1', Nuts => '2.4'};
  is $struct->{version}, '1.2';
}

#-------------------------------------------------------------------------------

{
  my ($author, $dist_archive, $pkg_name, $pkg_ver, $stack_name, $is_pinned)
      = parse_reg_spec('AUTHOR/Foo-1.2/Foo~2.0/my_stack/*');

  is $author,       'AUTHOR';
  is $dist_archive, 'Foo-1.2.tar.gz';
  is $pkg_name,     'Foo';
  is $pkg_ver,      '2.0';
  is $stack_name,   'my_stack';
  is $is_pinned,    1;
}

#-------------------------------------------------------------------------------

{
  my $t = Pinto::Tester->new;

  $t->populate('AUTHOR/FooAndBar-1.2=Foo~1.2,Bar~0.0');

  # Without .tar.gz extension
  $t->registration_ok('AUTHOR/FooAndBar-1.2/Foo~1.2/master');

  # With .tar.gz extension
  $t->registration_ok('AUTHOR/FooAndBar-1.2.tar.gz/Foo~1.2/master');

  # With explicit stack
  $t->registration_ok('AUTHOR/FooAndBar-1.2/Bar~0.0/master');

  # Without explicit stack
  $t->registration_ok('AUTHOR/FooAndBar-1.2/Bar~0.0');
}

#-------------------------------------------------------------------------------
done_testing;
