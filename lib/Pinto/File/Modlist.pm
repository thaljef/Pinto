# ABSTRACT: Generates a stub 03modlist.data.gz file

package Pinto::File::Modlist;

use Moose;
use MooseX::MarkAsMethods (autoclean => 1);

use PerlIO::gzip;

use Pinto::Types qw(File);
use Pinto::Exception qw(throw);

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

has stack => (
    is       => 'ro',
    isa      => 'Pinto::Schema::Result::Stack',
    required => 1,
);


has modlist_file  => (
    is      => 'ro',
    isa     => File,
    default => sub { $_[0]->stack->modules_dir->file('03modlist.data.gz') },
    lazy    => 1,
);

#------------------------------------------------------------------------------

sub write_modlist {
    my ($self) = @_;

    open my $fh, '>:gzip', $self->modlist_file or throw $!;
    print {$fh} $self->modlist_data;
    close $fh or throw $!;

    return $self;
}

#------------------------------------------------------------------------------

sub modlist_data {

    my $template = <<'END_MODLIST';
File:        03modlist.data
Description: This a placeholder for CPAN.pm
Modcount:    0
Written-By:  Id: %s
Date:        %s

package %s;

sub data { {} }

1;
END_MODLIST

    # If we put "package CPAN::Modulelist" in the above string, it
    # fools the PAUSE indexer into thinking that we provide the
    # CPAN::Modulelist package.  But we don't.  To get around this,
    # I'm going to inject the string "CPAN::Modulelist" into the
    # template.

    return sprintf $template, $0, scalar localtime, 'CPAN::Modulelist';
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------

1;

__END__
