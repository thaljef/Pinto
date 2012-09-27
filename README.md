# NAME

Pinto - Curate a repository of Perl modules

# VERSION

version 0.056

# SYNOPSIS

See [pinto](http://search.cpan.org/perldoc?pinto) to create and manage a Pinto repository.

See [pintod](http://search.cpan.org/perldoc?pintod) to allow remote access to your Pinto repository.

See [Pinto::Manual](http://search.cpan.org/perldoc?Pinto::Manual) for more information about the Pinto tools.

# DESCRIPTION

Pinto is a suite of tools and libraries for creating and managing a
custom CPAN-like repository of Perl modules.  The purpose of such a
repository is to provide a stable, curated stack of dependencies from
which you can reliably build, test, and delploy your application using
the standard Perl tool chain. Pinto supports various operations for
gathering and managing distribution dependencies within the
repository, so that you can control precisely which dependencies go
into your application.

# FEATURES

Pinto is inspired by [Carton](http://search.cpan.org/perldoc?Carton), [CPAN::Mini::Inject](http://search.cpan.org/perldoc?CPAN::Mini::Inject), and
[MyCPAN::App::DPAN](http://search.cpan.org/perldoc?MyCPAN::App::DPAN), but adds a few interesting features:

- Pinto supports mutiple indexes

A Pinto repository can have multiple indexes.  Each index corresponds
to a "stack" of dependencies that you can control.  So you can have
one stack for development, one for production, one for feature-xyz,
and so on.  You can also branch and merge stacks to experiment with
new dependencies or upgrades.

- Pinto helps manage incompatibilies between dependencies

Sometimes, you discover that a new version of a dependency is
incompatible with your application.  Pinto allows you to "pin" a
dependency to a stack, which prevents it from being accidentally
upgraded (either directly or via some other dependency).

- Pinto has built-in version control

When things go wrong, you can roll back any of the indexes in your
Pinto repository to a prior revision.  Also, you can view the complete
history of index changes as you add or upgrade dependencies.

- Pinto can pull archives from multiple remote repositories

Pinto can pull dependencies from multiple sources, so you can create
private (or public) networks of repositories that enable separate
teams or individuals to collaborate and share Perl modules.

- Pinto supports team development

Pinto is suitable for small to medium-sized development teams and
supports concurrent users.  Pinto also has a web service interface
(via [pintod](http://search.cpan.org/perldoc?pintod)), so remote developers can use a centrally hosted
repository.

- Pinto has a robust command line interface.

The [pinto](http://search.cpan.org/perldoc?pinto) utility has commands and options to control every aspect
of your Pinto repository.  They are well documented and behave in the
customary UNIX fashion.

- Pinto can be extended.

You can extend Pinto by creating [Pinto::Action](http://search.cpan.org/perldoc?Pinto::Action) subclasses to
perform new operations on your repository, such as extracting
documentation from a distribution, or grepping the source code of
several distributions.

# Pinto vs PAUSE

In some ways, Pinto is similar to [PAUSE](http://pause.perl.org).
Both are capable of accepting distributions and constructing a
directory structure and index that Perl installers understand.  But
there are some important differences:

- Pinto does not promise to index exactly like PAUSE does

Over the years, PAUSE has evolved complicated heuristics for dealing
with all the different ways that Perl code is written and packaged.
Pinto is much less sophisticated, and only aspires to produce an index
that is "good enough" for most situations.

- Pinto does not understand author permissions

PAUSE has a system of assigning ownership and co-maintenance
permission of modules to specific people.  Pinto does not have any
such permission system.  All activity is logged so you can identify
the culprit, but Pinto expects you to be accountable for your actions.

- Pinto is not (always) secure

PAUSE requires authors to authenticate themselves before they can
upload or remove modules.  Pinto does not require authentication, so
any user with sufficient file permission can potentialy change the
repository.  However [pintod](http://search.cpan.org/perldoc?pintod) does suport HTTP authentication, which
gives you some control over access to a remote repository.

# BUT WHERE IS THE API?

For now, the Pinto API is private and subject to radical change
without notice.  Any API documentation you see is purely for my own
references.  In the meantime, the command line utilities mentioned in
the ["SYNOPSIS"](#SYNOPSIS) are your public user interface.

# AUTHOR

Jeffrey Ryan Thalhammer <jeff@imaginative-software.com>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Imaginative Software Systems.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
