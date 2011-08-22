package Pinto::Exception::Args;

# ABSTRACT: Exception classes used by Pinto

#-----------------------------------------------------------------------------

# VERSION

#-----------------------------------------------------------------------------

use Exception::Class (

      'Pinto::Exception::Args' => { isa   => 'Pinto::Exception',
                                    alias => 'throw_args' },
);

use Readonly;
Readonly our @EXPORT_OK => qw(throw_args);

#-----------------------------------------------------------------------------

1;

__END__
