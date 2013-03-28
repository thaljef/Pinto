#!/bin/bash

##############################################################################
# THIS IS THE pinto INSTALLER
#
# This bash script will install pinto as a standalone application.  You must
# have cpanm installed first.  See http://cpanmin.us to install cpanm.
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
# All the depndencies for pinto come from a curated repository on 
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
# If you have any feedback or suggestions, please contact jeff@stratopan.com
# I'm especially keen to get suggestion on how to rig up this kind of 
# installation process for other platforms & environments (e.g. Windows, 
# csh, zsh, etc.)
#
##############################################################################

PINTO_REPO_URL=http://stratopan.com/Stratopan/Pinto/Production
PINTO_HOME=${PINTO_HOME:="$HOME/opt/local/pinto"}

echo "Installing pinto into $PINTO_HOME"

# TODO: check and carp if cpanm is not installed
cpanm --notest --quiet --mirror $PINTO_REPO_URL --mirror-only  \
      --local-lib-contained $PINTO_HOME Pinto App::Pinto

# TODO: send the build log and `perl -V` back for analysis
if [ $? -ne 0 ] ; then echo "Installation failed."; exit 1; fi

# Remove all scripts from bin, except pinto
(cd $PINTO_HOME/bin; ls | grep -v pinto | xargs rm)

cat <<END_MSG
pinto has been installed at $PINTO_HOME

Now add the following to your ~/.profile

  export PINTO_HOME=$PINTO_HOME
  export PATH=\$PINTO_HOME/bin:\$PATH

Thank you for installing pinto.  
Send feedback to jeff@stratopan.com
END_MSG

exit 0
