use utf8;
package Pinto::Schema::ResultSet::Distribution;

use strict;
use warnings;

use base 'DBIx::Class::ResultSet';

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

sub with_packages {
  my ($self, $where, $attrs) = @_;

  return $self->search->({}, {prefetch => 'packages'});
}

#------------------------------------------------------------------------------

sub find_by_sha256 {
  my ($self, $sha256) = @_;

  return $self->find({sha256 => $sha256}, {key => 'sha256_unique'});
}

#------------------------------------------------------------------------------

sub find_by_md5 {
  my ($self, $md5) = @_;

  return $self->find({md5 => $md5}, {key => 'md5_unique'});
}

#------------------------------------------------------------------------------

sub find_by_author_archive {
  my ($self, $author, $archive) = @_;

  my $where = {author_canonical => uc $author, archive => $archive};
  my $attrs = {key => 'author_canonical_archive_unique'};

  return $self->find($where, $attrs);
}

#------------------------------------------------------------------------------
1;

__END__
