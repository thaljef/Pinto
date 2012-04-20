# ABSTRACT: Inflate attributes into objects upon reading them

package Pinto::Meta::Attribute::Trait::Inflatable;

use Moose::Role;
use MooseX::Types::Moose qw(CodeRef Str);

use namespace::autoclean;

#-----------------------------------------------------------------------------

# VERSION

#-----------------------------------------------------------------------------

has inflator => (
   is        => 'ro',
   isa       => 'CodeRef | Str',
);

#-----------------------------------------------------------------------------

around _inline_get_value => sub {
    my $orig = shift;
    my $self = shift;
    my ($instance) = @_;

    my $source = join ' ', $self->$orig(@_);

    my $code = <<'END_CODE';
my $value = sub { %s }->(%s);
my $inflator = Class::MOP::class_of(%s)->find_attribute_by_name('%s')->inflator;
return ref $inflator ? $inflator->(%s, $value) : %s->$inflator($value);
END_CODE

    return sprintf $code,
                   $source, $instance,
                   $instance, quotemeta($self->name),
                   $instance, $instance;
};

#-----------------------------------------------------------------------------
## no critic qw(ProhibitMultiplePackages)

package Moose::Meta::Attribute::Custom::Trait::Inflatable;

sub register_implementation {return 'Pinto::Meta::Attribute::Trait::Inflatable'}

#-----------------------------------------------------------------------------
1;

__END__
