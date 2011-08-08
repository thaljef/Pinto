package Pinto::Distribution;

# ABSTRACT: Represents a Perl distribution

use Moose;
use MooseX::Types::Moose qw(Str);
use Pinto::Types qw(AuthorID File);
use Moose::Autobox;

use Carp;
use CPAN::DistnameInfo;
use Path::Class qw();
use Pinto::Util;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

has location => (
    is         => 'ro',
    isa        => Str,
);

has file       => (
    is         => 'ro',
    isa        => File,
    coerce     => 1,
);

has author   => (
    is         => 'ro',
    isa        => AuthorID,
    predicate  => 'has_author',
    writer     => '_set_author',
    coerce     => 1,
);

has packages => (
    is         => 'ro',
    isa        => 'ArrayRef[Pinto::Package]',
    default    => sub { [] },
);

has version    => (
    is         => 'ro',
    isa        => Str,
    init_arg   => undef,
    writer     => '_set_version',
);

has name => (
    is         => 'ro',
    isa        => Str,
    init_arg   => undef,
    writer     => '_set_name',
);

#------------------------------------------------------------------------------

sub BUILDARGS {
    my ($class, %args) = @_;

    croak 'Must specify either location or (file and author)'
        if not ($args{location} or ($args{file} and $args{author}));

    croak 'Cannot specify location with file or author'
        if $args{location} and ($args{file} or $args{author});

    croak 'Must specify file and author together'
        if $args{file} and not $args{author};


    if ($args{file} and $args{author}) {
        my $base = Path::Class::file($args{file})->basename();
        $args{location} = Pinto::Util::author_dir($args{author})->file($base)->stringify();
    }

    return \%args;
}

#------------------------------------------------------------------------------
# TODO: Delegate to a (lazy) DistnameInfo instead of using a BUILD

sub BUILD {
    my ($self, $args) = @_;

    my $dist_info = CPAN::DistnameInfo->new($self->location);
    $self->_set_version( $dist_info->version() || '');
    $self->_set_name( $dist_info->dist() || '');

    if (not $self->has_author() ) {
        $self->_set_author( $dist_info->cpanid() );
    }

    return $self;

}


#------------------------------------------------------------------------------

sub add_packages {
    my ($self, @packages) = @_;

    $self->packages->push(@packages);

    return $self;
}

#------------------------------------------------------------------------------

# Constructing from index
# $d = Dist->new(location => '/F/FO/FOO/Bar-1.0.tar.gz');
# $d->add_package(package => 'Bar', version => '1.3');

# Constructing from file
# $d = Dist->new(file => '/home/Bar-1.2.tar.gz', author => 'ME');

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#------------------------------------------------------------------------------
1;

__END__
