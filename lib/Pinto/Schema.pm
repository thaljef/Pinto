package Pinto::Schema;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Schema';

__PACKAGE__->load_namespaces;


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-09-04 17:03:04
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:hiBSzrLxcuMQ+7BAWzFFSw
#-------------------------------------------------------------------------------

use CPAN::PackageDetails;

sub get_package {
    my ($self, $package) = @_;

    return $self->resultset('Package')->find(name => $package);
}

#-------------------------------------------------------------------------------

sub get_indexed_package {
    my ($self, $package) = @_;

   return $self->resultset('Package')->indexed->find( {name => $package} );
}


#-------------------------------------------------------------------------------

sub get_distribution {
    my ($self, $dist) = @_;

    return $self->resultset('Distribution')->find( {location => $dist} );
}

#-------------------------------------------------------------------------------

sub write_index {
    my ($self, $index_file) = @_;

    my $details = CPAN::PackageDetails->new();
    my $index_rs = $self->resultset('Package')->indexed();

    while ( my $pkg = $index_rs->next() ) {
        $details->add_entry(
            package_name => $pkg->name(),
            version      => $pkg->version(),
            path         => $pkg->distribution->location(),
        );
    }

    $details->write_file($index_file);
}

#-------------------------------------------------------------------------------

sub load_foreign_index {
    my ($self, $index_file) = @_;

    # TODO: support "force";

    my $source = $self->config->source();
    my $temp_dir = File::Temp->newdir();
    my $index_url = URI->new("$source/modules/02packages.details.txt.gz");
    my $index_temp_file = file($temp_dir, '02packages.details.txt.gz');
    $self->fetch(url => $index_url, to => $index_temp_file);

    $self->logger->info("Loading foreign index file from $index_url");
    my $details = CPAN::PackageDetails->read( "$index_temp_file" );
    my ($records) = $details->entries->as_unique_sorted_list();

    my %dists;
    $dists{$_->path()}->{$_->package_name()} = $_->version() for @{$records};


    $DB::single = 1;
    foreach my $location ( sort keys %dists ) {

      next if $self->resultset('Distribution')->find( {location => $location} );
      $self->logger->info("Loading index data for $location");
      my $dist = $self->resultset('Distribution')->create(
          { location => $location,
            origin   => $source,
          }
      );

      foreach my $package (keys %{ $dists{$location} } ) {
        my $pkg = $self->resultset('Package')->create(
          { name         => $package,
            version      => $dists{$location}->{$package},
            distribution => $dist->id(),
          }
        );
      }
    }
}

#-------------------------------------------------------------------------------

sub all_packages {
    my ($self) = @_;

    return $self->resultset('Package')->every();
}

#-------------------------------------------------------------------------------

sub local_packages {
    my ($self) = @_;

    return $self->resultset('Package')->locals();
}

#------------------------------------------------------------------------------

sub foreign_packages {
    my ($self) = @_;

    return $self->resultset('Package')->foreigners();
}

#------------------------------------------------------------------------------

sub foreign_distributions {
    my ($self) = @_;

    return $self->resultset('Distribution')->foreigners();
}

#------------------------------------------------------------------------------

sub blocked_packages {
    my ($self) = @_;

    return $self->resultset('Package')->blocked();
}

#------------------------------------------------------------------------------

1;

__END__
