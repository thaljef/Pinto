package Pinto::Exceptions;

# ABSTRACT: Exception classes for Pinto

use strict;
use warnings;

#-----------------------------------------------------------------------------

# VERSION

#-----------------------------------------------------------------------------

use Exception::Class (

     'Pinto::Exception' => {
        alias => 'throw_error',
     },

     'Pinto::Exception::Action'  => {
        isa   => 'Pinto::Exception',
        alias => 'throw_action',
     },

     'Pinto::Exception::Fatal'  => {
        isa   => 'Pinto::Exception',
        alias => 'throw_fatal',
     },

     'Pinto::Exception::IllegalArguments'  => {
         isa   => 'Pinto::Exception::Fatal',
         alias => 'throw_args',
     },

     'Pinto::Exception::InputOutput'  => {
         isa   => 'Pinto::Exception::Fatal',
         alias => 'throw_io',
     },

     'Pinto::Exception::Database'  => {
         isa   => 'Pinto::Exception::Fatal',
         alias => 'throw_db',
     },

     'Pinto::Exception::DuplicateDistribution'  => {
         isa   => 'Pinto::Exception',
         alias => 'throw_dupe',
     },

     'Pinto::Exception::DistributionNotFound'  => {
         isa   => 'Pinto::Exception',
         alias => 'throw_nodist',
     },

     'Pinto::Exception::DistributionParse'  => {
         isa   => 'Pinto::Exception',
         alias => 'throw_dist_parse',
     },

     'Pinto::Exception::EmptyDistribution'  => {
         isa   => 'Pinto::Exception',
         alias => 'throw_empty_dist',
     },

     'Pinto::Exception::UnauthorizedPackage'  => {
         isa   => 'Pinto::Exception',
         alias => 'throw_unauthorized',
     },

     'Pinto::Exception::IllegalVersion'  => {
         isa   => 'Pinto::Exception',
         alias => 'throw_version',
     },

     'Pinto::Exception::VCS'  => {
         isa   => 'Pinto::Exception::Fatal',
         alias => 'throw_vcs',
     },
);

#-----------------------------------------------------------------------------

use base 'Exporter';

our @EXPORT_OK = qw(throw_error throw_action throw_fatal throw_version);

#-----------------------------------------------------------------------------

1;

__END__
