#!/bin/sh

PINTO_HOME=${PINTO_HOME:="$HOME/opt/local/pinto"}
PATH=$PINTO_HOME/bin:$PATH

echo "Installing pinto into $PINTO_HOME"

PINTO_REPO_URL=http://stratopan.com/Stratopan/Pinto/Production
cpanm --notest --quiet --mirror $PINTO_REPO_URL --mirror-only  --local-lib-contained $PINTO_HOME App::Pinto Pinto
if [ $? -ne 0 ] ; then echo "Installation failed.  See the cpanm build log for details"; exit 1; fi

cat <<END_MSG
pinto has been installed at $PINTO_HOME

Now add the following to your ~/.profile

  export PINTO_HOME=$PINTO_HOME
  export PATH=\$PINTO_HOME/bin:\$PATH

Thank you for trying pinto.  
Send feedback to thaljef@cpan.org
END_MSG

exit 0;