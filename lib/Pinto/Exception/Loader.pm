package Pinto::Exception::Loader;

# ABSTRACT: Exception class used by Pinto

#-----------------------------------------------------------------------------

# VERSION

#-----------------------------------------------------------------------------

use Exception::Class (

      'Pinto::Exception::Loader' => { isa   => 'Pinto::Exception',
                                    alias => 'throw_load' },
);

use Readonly;
Readonly our @EXPORT_OK => qw(throw_load);

#-----------------------------------------------------------------------------

1;

__END__
