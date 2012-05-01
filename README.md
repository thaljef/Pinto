# NAME

Pinto - Curate a repository of Perl modules

# VERSION

version 0.040_001

# SYNOPSIS

See [pinto-admin](http://search.cpan.org/perldoc?pinto-admin) to create and manage a Pinto repository.

See [pinto-server](http://search.cpan.org/perldoc?pinto-server) to open remote access to a Pinto repository.

See [pinto-remote](http://search.cpan.org/perldoc?pinto-remote) to interact with a remote Pinto repository.

See [Pinto::Manual](http://search.cpan.org/perldoc?Pinto::Manual) for more information about the Pinto tools.

# DESCRIPTION

Pinto is a suite of tools for creating and managing a CPAN-like
repository of Perl archives.  Pinto is inspired by [CPAN::Mini](http://search.cpan.org/perldoc?CPAN::Mini),
[CPAN::Mini::Inject](http://search.cpan.org/perldoc?CPAN::Mini::Inject), and [MyCPAN::App::DPAN](http://search.cpan.org/perldoc?MyCPAN::App::DPAN), but adds a few
interesting features:

- Pinto supports several usage patterns

With Pinto, you can create a repository to mirror all the latest
distributions from another repository.  Or you can create a "sparse
repository" with just your own private distributions.  Or you can
create a "project repository" that has all the distributions required
for a particular project.  Or you can combine any of the above in some
way.

- Pinto supports adding AND removing archives from the repository

Pinto gives you the power to precisely tune the contents of your
repository.  So you can be sure that your downstream clients get
exactly the stack of dependencies that you want them to have.

- Pinto can be integrated with your version control system

Pinto can automatically commit to your version control system whenever
the contents of the repository changes.  This gives you repeatable and
identifiable snapshots of your dependencies, and a mechanism for
rollback when things go wrong.

- Pinto makes it easier to build several local repositories

Creating new Pinto repositories is easy, and each has its own
configuration.  So you can have different repositories for each
department, or each project, or each version of perl, or each
customer, or whatever you want.

- Pinto can pull archives from multiple remote repositories

Pinto can mirror or import distributions from multiple sources, so you
can create private (or public) networks of repositories that enable
separate teams or individuals to collaborate and share distributions.

- Pinto supports team development

Pinto is suitable for small to medium-sized development teams, where
several developers might contribute new distributions at the same
time.  Pinto ensures that concurrent users don't step on each other.

- Pinto has a robust command line interface.

The [pinto-admin](http://search.cpan.org/perldoc?pinto-admin) and [pinto-remote](http://search.cpan.org/perldoc?pinto-remote) command line tools have options
to control every aspect of your Pinto repository.  They are well
documented and behave in the customary UNIX fashion.

- Pinto can be extended.

You can extend Pinto by creating [Pinto::Action](http://search.cpan.org/perldoc?Pinto::Action) subclasses to
perform new operations on your repository, such as extracting
documentation from a distribution, or grepping the source code of
several distributions.

In some ways, Pinto is also similar to [PAUSE](http://pause.perl.org).
Both are capable of accepting distributions and constructing a
directory structure and index that toolchain clients understand.  But
there are some important differences:

- Pinto does not promise to index exactly like PAUSE does

Over the years, PAUSE has evolved complicated heuristics for dealing
with all the different ways that Perl code is written and
distributions are organized.  Pinto is much less sophisticated, and
only aspires to produce an index that is "good enough" for most
applications.

- Pinto does not understand author permissions

PAUSE has a system of assigning ownership and co-maintenance
permission to individuals or groups.  But Pinto only has a basic
"first-come" system of ownership.  The ownership controls are only
advisory and can easily be bypassed (see next item below).

- Pinto is not secure

PAUSE requires authors to authenticate themselves before they can
upload or remove distributions.  However, Pinto does not authenticate
and permits users masquerade as anybody they want to be.  This is
actually intentional and designed to encourage collaboration among
developers.

# METHODS

## run( $action_name => %action_args )

Runs the Action with the given `$action_name`, passing the
`%action_args` to its constructor.  Returns a [Pinto::Result](http://search.cpan.org/perldoc?Pinto::Result).

## add_logger( $obj )

Convenience method for installing additional endpoints for logging.
The object must be an instance of a [Log::Dispatch::Output](http://search.cpan.org/perldoc?Log::Dispatch::Output) subclass.

# BUT WHERE IS THE API?

For now, the Pinto API is private and subject to radical change
without notice.  Any module documentation you see is purely for my own
references.  In the meantime, the command line utilities mentioned in
the ["SYNOPSIS"](#SYNOPSIS) are your public user interface.

# SUPPORT

## Perldoc

You can find documentation for this module with the perldoc command.

    perldoc Pinto

## Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

- Search CPAN

The default CPAN search engine, useful to view POD in HTML format.

[http://search.cpan.org/dist/Pinto](http://search.cpan.org/dist/Pinto)

- CPAN Ratings

The CPAN Ratings is a website that allows community ratings and reviews of Perl modules.

[http://cpanratings.perl.org/d/Pinto](http://cpanratings.perl.org/d/Pinto)

- CPAN Testers

The CPAN Testers is a network of smokers who run automated tests on uploaded CPAN distributions.

[http://www.cpantesters.org/distro/P/Pinto](http://www.cpantesters.org/distro/P/Pinto)

- CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

[http://matrix.cpantesters.org/?dist=Pinto](http://matrix.cpantesters.org/?dist=Pinto)

- CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

[http://deps.cpantesters.org/?module=Pinto](http://deps.cpantesters.org/?module=Pinto)

## Bugs / Feature Requests

[https://github.com/thaljef/Pinto/issues](https://github.com/thaljef/Pinto/issues)

## Source Code



[https://github.com/thaljef/Pinto](https://github.com/thaljef/Pinto)

    git clone git://github.com/thaljef/Pinto.git

# AUTHOR

Jeffrey Ryan Thalhammer <jeff@imaginative-software.com>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Imaginative Software Systems.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.