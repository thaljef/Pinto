# ABSTRACT: Common queries for Distributions

use utf8;
package Pinto::Schema::ResultSet::Distribution;

use strict;
use warnings;

use base 'DBIx::Class::ResultSet';

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

sub with_packages {
  my ($self, $where) = @_;

  return $self->search($where || {}, {prefetch => 'packages'});
}

#------------------------------------------------------------------------------

sub find_by_author_archive {
  my ($self, $author, $archive) = @_;

  my $where = {author => $author, archive => $archive};
  my $attrs = {key => 'author_archive_unique'};

  return $self->find($where, $attrs);
}

#------------------------------------------------------------------------------
1;

__END__
