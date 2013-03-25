#!/bin/sh

export PINTO_HOME=$HOME/usr/local/pinto
export PATH=$PINTO_HONE/bin:$PATH

PINTO_REPO_URL=http://stratopan.com/stratopan/pinto
cpanm --mirror $PINTO_REPO_URL --mirror-only  App::Pinto Pinto

echo <<END_MSG
pinto has been installed at $PINTO_HOME

Now add the following to your ~/.profile

  export PINTO_HOME=$PINTO_HOME
  export PATH=\$PINTO_HOME/:\$PATH
END_MSG

exit 0;