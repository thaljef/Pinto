# ABSTRACT: Constants used across the Pinto utilities

package Pinto::Constants;

use strict;
use warnings;

use URI;
use Readonly;
use Exporter qw(import);

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

Readonly our @EXPORT_OK => qw(

    $PINTO_SERVER_DEFAULT_PORT
    $PINTO_SERVER_DEFAULT_HOST
    $PINTO_SERVER_DEFAULT_ROOT

    $PINTO_SERVER_STATUS_OK
    $PINTO_SERVER_DIAG_PREFIX
    $PINTO_SERVER_NULL_MESSAGE
    $PINTO_SERVER_PROGRESS_MESSAGE

    $PINTO_DEFAULT_COLORS
    $PINTO_COLOR_0
    $PINTO_COLOR_1
    $PINTO_COLOR_2

    $PINTO_LOCK_TYPE_SHARED
    $PINTO_LOCK_TYPE_EXCLUSIVE

    $PINTO_STACK_NAME_ALL

    $PINTO_AUTHOR_REGEX
    $PINTO_USERNAME_REGEX
    $PINTO_STACK_NAME_REGEX
    $PINTO_PROPERTY_NAME_REGEX
    $PINTO_REVISION_ID_REGEX

    $PINTO_MINIMUM_CPANM_VERSION

    $PINTO_DIFF_STYLE_CONCISE
    $PINTO_DIFF_STYLE_DETAILED
    @PINTO_DIFF_STYLES

    $PINTO_STRATOPAN_CPAN_URI
    $PINTO_STRATOPAN_LOCATOR_URI
    $PINTO_BACKPAN_CPAN_URI
    @PINTO_DEFAULT_SOURCE_URIS

    @PINTO_PREREQ_PHASES
    @PINTO_PREREQ_RELATIONS
);

Readonly our %EXPORT_TAGS => (
    all        => \@EXPORT_OK,
    color      => [ grep {m/COLOR/x} @EXPORT_OK ],
    server     => [ grep {m/SERVER/x} @EXPORT_OK ],
    regex      => [ grep {m/REGEX/x} @EXPORT_OK ],
    lock       => [ grep {m/LOCK/x} @EXPORT_OK ],
    diff       => [ grep {m/DIFF/x} @EXPORT_OK ],
    prereq     => [ grep {m/PREREQ/x} @EXPORT_OK ],
    stratopan  => [ grep {m/STRATOPAN/x} @EXPORT_OK ],
);

#------------------------------------------------------------------------------

Readonly our $PINTO_SERVER_DEFAULT_HOST => 'localhost';

Readonly our $PINTO_SERVER_DEFAULT_PORT => 3111;

Readonly our $PINTO_SERVER_DEFAULT_ROOT => "http://$PINTO_SERVER_DEFAULT_HOST:$PINTO_SERVER_DEFAULT_PORT";

#------------------------------------------------------------------------------

Readonly our $PINTO_SERVER_DIAG_PREFIX => '## ';

Readonly our $PINTO_SERVER_STATUS_OK => "${PINTO_SERVER_DIAG_PREFIX}Status: ok";

Readonly our $PINTO_SERVER_NULL_MESSAGE => "${PINTO_SERVER_DIAG_PREFIX}-- ##";

Readonly our $PINTO_SERVER_PROGRESS_MESSAGE => "${PINTO_SERVER_DIAG_PREFIX}. ##";

#------------------------------------------------------------------------------

Readonly our $PINTO_DEFAULT_COLORS => [qw(green yellow red)];

Readonly our $PINTO_COLOR_0 => 0;
Readonly our $PINTO_COLOR_1 => 1;
Readonly our $PINTO_COLOR_2 => 2;

#------------------------------------------------------------------------------

Readonly our $PINTO_LOCK_TYPE_SHARED    => 'SH';
Readonly our $PINTO_LOCK_TYPE_EXCLUSIVE => 'EX';

#------------------------------------------------------------------------------

Readonly our $PINTO_STACK_NAME_ALL => '%';

#------------------------------------------------------------------------------

Readonly my $PINTO_ALPHANUMERIC_REGEX     => qr{^ [a-zA-Z0-9-._]+ $}x;
Readonly my $PINTO_HEXADECIMAL_UUID_REGEX => qr{^ [a-f0-9-]+      $}x;

Readonly our $PINTO_AUTHOR_REGEX        => qr/^ [A-Z]{2} [-A-Z0-9]* $/x;
Readonly our $PINTO_USERNAME_REGEX      => $PINTO_ALPHANUMERIC_REGEX;
Readonly our $PINTO_STACK_NAME_REGEX    => $PINTO_ALPHANUMERIC_REGEX;
Readonly our $PINTO_PROPERTY_NAME_REGEX => $PINTO_ALPHANUMERIC_REGEX;
Readonly our $PINTO_REVISION_ID_REGEX   => $PINTO_HEXADECIMAL_UUID_REGEX;

#------------------------------------------------------------------------------

Readonly our $PINTO_MINIMUM_CPANM_VERSION => '1.6920';

#------------------------------------------------------------------------------

Readonly our $PINTO_DIFF_STYLE_CONCISE  => 'concise';
Readonly our $PINTO_DIFF_STYLE_DETAILED => 'detailed';

Readonly our @PINTO_DIFF_STYLES => ($PINTO_DIFF_STYLE_CONCISE, $PINTO_DIFF_STYLE_DETAILED);

#------------------------------------------------------------------------------
# TODO: Make these configurable via ENV vars

Readonly our $PINTO_PUBLIC_CPAN_URI       => URI->new('http://www.cpan.org');
Readonly our $PINTO_BACKPAN_CPAN_URI      => URI->new('http://backpan.perl.org');
Readonly our $PINTO_STRATOPAN_CPAN_URI    => URI->new('http://cpan.stratopan.com'); 
Readonly our $PINTO_STRATOPAN_LOCATOR_URI => URI->new('http://meta.stratopan.com/locate');

Readonly our @PINTO_DEFAULT_SOURCE_URIS => ( $PINTO_STRATOPAN_CPAN_URI, 
                                             $PINTO_PUBLIC_CPAN_URI, 
                                             $PINTO_BACKPAN_CPAN_URI );

#------------------------------------------------------------------------------

Readonly our @PINTO_PREREQ_PHASES => qw(configure build test runtime develop);
Readonly our @PINTO_PREREQ_RELATIONS => qw(requires suggests recommends);

#------------------------------------------------------------------------------
1;

__END__
