package Pinto::Action::Get;

# ABSTRACT: Get a remote module (and its dependencies) in your repository

use Moose;

use MooseX::Types::Moose qw(Str);
use Pinto::Types qw(URI);

use Pinto::Exceptions qw(throw_error);

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------
# ISA

extends 'Pinto::Action';

#------------------------------------------------------------------------------
# Moose Attributes

has module => (
   is       => 'ro',
   isa      => Str,
   required => 1,
);

#------------------------------------------------------------------------------
# Moose Roles

with qw(Pinto::Role::UserAgent);

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    my @queue = ( $self->module() );
    my $count = 0;

    while (@queue) {

        my $module = pop @queue;
        my $archive;

        if (my $local_dist = $self->db->get_latest_package_with_name($module)) {
            $self->info("Found $module in local repository at $local_dist");
            $archive = $local_dist->native_path();
        }
        elsif (my $remote_dist_url = $self->find_module_by_name($module)) {
           $self->info("Found $module in remote repository at $remote_dist_url");
           $archive = $self->fetch_temporary(url => $remote_dist_url);
           $self->db->add_distribution($archive);
        }
        else {
            throw_error("Could not find $module anywhere");
        }


        my $extractor = Pinto::Extractor->new( logger => $self->logger() );
        push @queue, $extractor->dependencies(archive => $archive);
        $count++
    }

    $self->add_message("Got $count distributions");

    return 1;
}

#------------------------------------------------------------------------------

sub find_module_by_name {
  my ($self, $module_name) = @_;

  for my $source ($self->config->sources_list()) {
      my $idx   = Pinto::IndexReader->new(source => $source,
                                          logger => $self->logger());
      my $found = $idx->modules()->{$module_name};
      return $source . '/authors/id/' . $found->{path} if $found;
   }

  return;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#------------------------------------------------------------------------------

1;

__END__
