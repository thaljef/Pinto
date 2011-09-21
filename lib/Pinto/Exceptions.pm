package Pinto::Exceptions;

# ABSTRACT: Exception classes for Pinto

use strict;
use warnings;

#-----------------------------------------------------------------------------

# VERSION

#-----------------------------------------------------------------------------

use Exception::Class (

    'Pinto::Exception',

    'Pinto::Exception::Fatal'  => {
        isa   => 'Pinto::Exception',
        alias => 'throw_fatal'
     },

     'Pinto::Exception::IllegalArguments'  => {
         isa   => 'Pinto::Exception::Fatal',
         alias => 'throw_args'
     },

     'Pinto::Exception::InputOutput'  => {
         isa   => 'Pinto::Exception::Fatal',
         alias => 'throw_io'
     },

     'Pinto::Exception::Database'  => {
         isa   => 'Pinto::Exception::Fatal',
         alias => 'throw_db'
     },

     'Pinto::Exception::UserAgent'  => {
         isa   => 'Pinto::Exception',
         alias => 'throw_ua'
     },

     'Pinto::Exception::DuplicateDistribution'  => {
         isa   => 'Pinto::Exception',
         alias => 'throw_dupe'
     },

     'Pinto::Exception::DistributionNotFound'  => {
         isa   => 'Pinto::Exception',
         alias => 'throw_nodist'
     },

     'Pinto::Exception::DistributionParse'  => {
         isa   => 'Pinto::Exception',
         alias => 'throw_dist_parse'
     },

     'Pinto::Exception::EmptyDistribution'  => {
         isa   => 'Pinto::Exception',
         alias => 'throw_empty_dist'
     },

     'Pinto::Exception::UnauthorizedPackage'  => {
         isa   => 'Pinto::Exception',
         alias => 'throw_unauthorized'
     },

     'Pinto::Exception::IllegalVersion'  => {
         isa   => 'Pinto::Exception',
         alias => 'throw_version'
     },

     'Pinto::Exception::VCS'  => {
         isa   => 'Pinto::Exception::Fatal',
         alias => 'throw_vcs'
     },
);

#-----------------------------------------------------------------------------

use base 'Exporter';

our @EXPORT_OK = qw(throw_fatal throw_args throw_io throw_ua throw_db
                    throw_dupe throw_version throw_vcs throw_nodist
                    throw_unauthorized throw_empty_dist throw_dist_parse);

#-----------------------------------------------------------------------------

1;

__END__
