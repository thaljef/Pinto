package Pinto::Schema::Result::Distribution;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Pinto::Schema::Result::Distribution

=cut

__PACKAGE__->table("distribution");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 name

  data_type: 'text'
  is_nullable: 0

=head2 author

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 is_local

  data_type: 'integer'
  is_nullable: 0

=head2 source

  data_type: 'text'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "name",
  { data_type => "text", is_nullable => 0 },
  "author",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "is_local",
  { data_type => "integer", is_nullable => 0 },
  "source",
  { data_type => "text", is_nullable => 0 },
);
__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 author

Type: belongs_to

Related object: L<Pinto::Schema::Result::Author>

=cut

__PACKAGE__->belongs_to(
  "author",
  "Pinto::Schema::Result::Author",
  { id => "author" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 packages

Type: has_many

Related object: L<Pinto::Schema::Result::Package>

=cut

__PACKAGE__->has_many(
  "packages",
  "Pinto::Schema::Result::Package",
  { "foreign.distribution" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-09-04 17:03:04
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Y8JReoPTxxh4E+xseJYZiw

#-------------------------------------------------------------------------------

use URI;
use Dist::Metadata 0.920; # supports .zip
use CPAN::DistnameInfo;
use Path::Class qw();

use Pinto::Util;
use Pinto::Package;
use Pinto::Exception::Args qw(throw_args);
use Pinto::Exception::IO qw(throw_io);

use overload ('""' => 'to_string');

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

1;

__END__
