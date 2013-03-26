#!/bin/sh

export PINTO_HOME=$HOME/usr/local/pinto
export PATH=$PINTO_HOME/bin:$PATH

echo "Installing pinto into $PINTO_HOME.  This will take a while."
echo 'You mail tail ~/.cpanm/build.log if you want to follow along.'

PINTO_REPO_URL=http://stratopan.com/Stratopan/Pinto/Production
cpanm --notest --quiet --mirror $PINTO_REPO_URL --mirror-only  --local-lib-contained $PINTO_HOME App::Pinto Pinto
if [ $? -ne 0 ] ; then echo "Installation failed.  See the cpanm build log for details"; exit 1; fi

echo <<END_MSG
pinto has been installed at $PINTO_HOME

Now add the following to your ~/.profile

  export PINTO_HOME=$PINTO_HOME
  export PATH=\$PINTO_HOME/:\$PATH

Thank you for trying pinto.  
Send feeback to thaljef@cpan.org
END_MSG

exit 0;