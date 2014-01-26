#!/bin/bash

##############################################################################
# THIS IS THE PINTO INSTALLER
#
# This bash script will install pinto as a standalone application.
#
# By default, pinto and all of its dependencies will be built into the 
# ~/opt/local/pinto directory.  You can change this location by setting the
# PINTO_HOME environment variable before running this script.
#
# The purpose of a standalone installation is to isolate pinto from whatever
# other Perl modules you may have in your environment.  So if you ever upgrade
# or change those modules, pinto will not be affected.  Nor does installing 
# pinto affect any of the modules your other apps are using.
#
# The most common way to run this installer is like this:
#
#   curl -L http://getpinto.stratopan.com | bash
#
# Or if you prefer to use wget then run this command:
#
#   wget -O - http://getpinto.stratopan.com | bash
#
# After a succesful installation, you'll be instructed on how to amend your
# ~/.profile (or ~/.bashrc, or whatever you prefer) so that pinto runs
# naturally in your everyday shell environment.
#
# All the depndencies for pinto come from a curated repository on hosted
# http://stratopan.com.  That repository contains specific versions of all 
# the modules that pinto needs.  So those may not be the latest versions,
# but they are versions that I know will work (and that's the whole point
# of having a pinto repository anyway).
#
# If this installer doesn't work for you, then you can fallback to installing
# the App::Pinto module from CPAN.  Again, cpanm(1) is really excellent for
# that, but you can use cpan(1) too.  When installing from CPAN, you'll be 
# getting the versions of modules that are in the CPAN index at that moment, 
# which may or may not be 100% compatible with pinto (usually they are, but 
# you never know).
#
# CONFIGURATION
#
# The following environment variables can be used to control the installation:
#
# PINTO_HOME
#
#   Sets the directory where pinto will be installed. 
#   Defaults to $HOME/opt/local/pinto
#
# PINTO_REPO_URL
#
#   Sets the URL of the repository that provides pinto's dependencies
#   Defaults to https://stratopan.com/thaljef/OpenSource/pinto-release
#
# PINTO_INSTALLER_AGENT
#
#   Sets the name of the tool that will be used to fetch cpanm.  If set, 
#   it must be either 'curl' or 'wget'.  If not set, the installer will
#   fallback to either 'curl' or 'wget' (in that order) depending on what
#   you already have installed.
#
# PERL_CPANM_OPT
#
#   Sets the default options for cpanm, which is used to install pinto.  This
#   can be useful if you need to specify a certain agent such as lwp, curl,
#   or wget.  See https://metacpan.org/module/cpanm for more details.
#
# Copyright 2013 Jeffrey Ryan Thalhammer <jeff@stratopan.com>
#
##############################################################################

set -ue

#-----------------------------------------------------------------------------
# You can set these variables beforehand to override defaults

PINTO_REPO_URL=${PINTO_REPO_URL:="https://stratopan.com/thaljef/OpenSource/pinto-release"}
PINTO_HOME=${PINTO_HOME:="$HOME/opt/local/pinto"}

#-----------------------------------------------------------------------------
# Decide which agent to use.  Set PINTO_INSTALLER_AGENT to override

if  [ -z ${PINTO_INSTALLER_AGENT:-} ]; then

    if type curl > /dev/null 2>&1; then
        PINTO_INSTALLER_AGENT='curl'
    elif type wget > /dev/null 2>&1; then 
        PINTO_INSTALLER_AGENT='wget'
    else
        echo "Must have curl or wget to install pinto"
        exit 1
    fi
fi

#-----------------------------------------------------------------------------
# Bootstrap cpanm

CPANM_URL="https://raw.github.com/thaljef/Pinto/master/etc/cpanm"
PINTO_SBIN="$PINTO_HOME/sbin"
PINTO_CPANM_EXE="$PINTO_SBIN/cpanm"

mkdir -p "$PINTO_SBIN"

if   [ $PINTO_INSTALLER_AGENT = 'curl' ]; then
	curl --silent --show-error --location $CPANM_URL > "$PINTO_CPANM_EXE"
elif [ $PINTO_INSTALLER_AGENT = 'wget' ]; then 
	wget --no-verbose --output-document - $CPANM_URL > "$PINTO_CPANM_EXE"
else
	echo "Invalid PINTO_INSTALLER_AGENT ($PINTO_INSTALLER_AGENT)."
        echo "If set, PINTO_INSTALLER_AGENT must be 'curl' or 'wget'".
        exit 1;
fi

chmod 755 "$PINTO_CPANM_EXE"

#-----------------------------------------------------------------------------
# Do installation

echo "Installing pinto into $PINTO_HOME"

"$PINTO_CPANM_EXE" --notest --quiet --mirror $PINTO_REPO_URL --mirror-only  \
      --local-lib-contained "$PINTO_HOME" --man-pages Pinto

# TODO: send the build log and `perl -V` back for analysis
if [ $? -ne 0 ] ; then echo "Installation failed."; exit 1; fi

#-----------------------------------------------------------------------------
# Remove scripts and man pages that aren't from pinto

(cd "$PINTO_HOME/bin";      ls | grep -iv pinto | xargs rm -f)
(cd "$PINTO_HOME/man/man1"; ls | grep -iv pinto | xargs rm -f)
(cd "$PINTO_HOME/man/man3"; ls | grep -iv pinto | xargs rm -f)

#-----------------------------------------------------------------------------
# Create the etc/ directory

PINTO_ETC="$PINTO_HOME/etc"
mkdir -p "$PINTO_ETC"

#-----------------------------------------------------------------------------
# Write the bash setup file in etc/

PINTO_BASHRC="$PINTO_ETC/bashrc"

cat > "$PINTO_BASHRC" <<END_CONFIG
###        THIS IS A GENERATED FILE -- DO NOT EDIT         ###
export PINTO_HOME="$PINTO_HOME"
export PATH="\$PINTO_HOME/bin:\$PATH"
export MANPATH="\$PINTO_HOME/man:\$MANPATH"

###        PUT YOUR CUSTOMIZATIONS IN \$HOME/.pintorc      ###
if [ -f "\$HOME/.pintorc" ]; then source "\$HOME/.pintorc"; fi
END_CONFIG

#-----------------------------------------------------------------------------
# Display instructions

cat <<END_MSG
pinto has been installed at $PINTO_HOME.  
To activate it, give this command:

  source $PINTO_HOME/etc/bashrc

To make pinto part of your everyday environment, add that 
last command to your ~/.profile or ~/.bashrc file as well.

We want your feedback!  Help us make Pinto better by
writing a review of Pinto at http://cpanratings.perl.org.

Got questions about Pinto?  We have the answers!  Contact
us at team@stratopan.com or on the #pinto channel on IRC.
END_MSG

#-----------------------------------------------------------------------------
# Done

exit 0
