# NAME

Pinto - Curate a repository of Perl modules

# VERSION

version 0.092

# SYNOPSIS

See [pinto](http://search.cpan.org/perldoc?pinto) to create and manage a Pinto repository.

See [pintod](http://search.cpan.org/perldoc?pintod) to allow remote access to your Pinto repository.

See [Pinto::Manual](http://search.cpan.org/perldoc?Pinto::Manual) for more information about the Pinto tools.

[Stratopan](http://stratopan.com) for hosting your Pinto repository in the cloud.

# DESCRIPTION

Pinto is an application for creating and managing a custom CPAN-like 
repository of Perl modules.  The purpose of such a repository is to 
provide a stable, curated stack of dependencies from which you can 
reliably build, test, and deploy your application using the standard 
Perl tool chain. Pinto supports various operations for gathering and 
managing distribution dependencies within the repository, so that you 
can control precisely which dependencies go into your application.

# FEATURES

Pinto is inspired by [Carton](http://search.cpan.org/perldoc?Carton), [CPAN::Mini::Inject](http://search.cpan.org/perldoc?CPAN::Mini::Inject), and
[MyCPAN::App::DPAN](http://search.cpan.org/perldoc?MyCPAN::App::DPAN), but adds a few interesting features:

- Pinto supports multiple indexes

    A Pinto repository can have multiple indexes.  Each index corresponds
    to a "stack" of dependencies that you can control.  So you can have
    one stack for development, one for production, one for feature-xyz,
    and so on.  You can also branch and merge stacks to experiment with
    new dependencies or upgrades.

- Pinto helps manage incompatibles between dependencies

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

- Pinto does not enforce security

    PAUSE requires authors to authenticate themselves before they can
    upload or remove modules.  Pinto does not require authentication, so
    any user with sufficient file permission can potentially change the
    repository.  However [pintod](http://search.cpan.org/perldoc?pintod) does support HTTP authentication, which
    gives you some control over access to a remote repository.

# BUT WHERE IS THE API?

For now, the Pinto API is private and subject to radical change
without notice.  Any API documentation you see is purely for my own
references.  In the meantime, the command line utilities mentioned in
the ["SYNOPSIS"](#SYNOPSIS) are your public user interface.

# SUPPORT

## Perldoc

You can find documentation for this module with the perldoc command.

    perldoc Pinto

## Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

- MetaCPAN

    A modern, open-source CPAN search engine, useful to view POD in HTML format.

    [http://metacpan.org/release/Pinto](http://metacpan.org/release/Pinto)

- CPAN Ratings

    The CPAN Ratings is a website that allows community ratings and reviews of Perl modules.

    [http://cpanratings.perl.org/d/Pinto](http://cpanratings.perl.org/d/Pinto)

- CPANTS

    The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

    [http://cpants.perl.org/dist/overview/Pinto](http://cpants.perl.org/dist/overview/Pinto)

- CPAN Testers

    The CPAN Testers is a network of smokers who run automated tests on uploaded CPAN distributions.

    [http://www.cpantesters.org/distro/P/Pinto](http://www.cpantesters.org/distro/P/Pinto)

- CPAN Testers Matrix

    The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

    [http://matrix.cpantesters.org/?dist=Pinto](http://matrix.cpantesters.org/?dist=Pinto)

- CPAN Testers Dependencies

    The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

    [http://deps.cpantesters.org/?module=Pinto](http://deps.cpantesters.org/?module=Pinto)

## Internet Relay Chat

You can get live help by using IRC ( Internet Relay Chat ). If you don't know what IRC is,
please read this excellent guide: [http://en.wikipedia.org/wiki/Internet\_Relay\_Chat](http://en.wikipedia.org/wiki/Internet\_Relay\_Chat). Please
be courteous and patient when talking to us, as we might be busy or sleeping! You can join
those networks/channels and get help:

- irc.perl.org

    You can connect to the server at 'irc.perl.org' and join this channel: \#pinto then talk to this person for help: thaljef.

## Bugs / Feature Requests

[https://github.com/thaljef/Pinto/issues](https://github.com/thaljef/Pinto/issues)

## Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

[https://github.com/thaljef/Pinto](https://github.com/thaljef/Pinto)

    git clone git://github.com/thaljef/Pinto.git

# CONTRIBUTORS

- BenRifkah Bergsten-Buret <mail.spammagnet+github@gmail.com>
- Boris Däppen <bdaeppen.perl@gmail.com>
- Cory G Watson <gphat@onemogin.com>
- David Steinbrunner <dsteinbrunner@pobox.com>
- Glenn Fowler <cebjyre@cpan.org>
- Jakob Voss <jakob@nichtich.de>
- Jeffrey Ryan Thalhammer <jeff@imaginative-software.com>
- Karen Etheridge <ether@cpan.org>
- Michael G. Schwern <schwern@pobox.com>
- Oleg Gashev <oleg@gashev.net>
- Steffen Schwigon <ss5@renormalist.net>
- Tommy Stanton <tommystanton@gmail.com>
- Wolfgang Kinkeldei <wolfgang@kinkeldei.de>
- Yanick Champoux <yanick@babyl.dyndns.org>
- hesco <hesco@campaignfoundations.com>
- popl <popl\_likes\_to\_code@yahoo.com>

# AUTHOR

Jeffrey Ryan Thalhammer <jeff@stratopan.com>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Jeffrey Ryan Thalhammer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
