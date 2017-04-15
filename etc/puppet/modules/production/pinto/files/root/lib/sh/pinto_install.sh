#!/bin/bash
set -e 

export HOME=/opt/local/pinto
cd $HOME

if [[ ! `grep PINTO_URL_CREDS /root/.bashrc | wc -l` > 0 ]] ; then 
    /bin/echo "export PINTO_HOME=/opt/local/pinto" >> /root/.bashrc ;
    /bin/echo "export PINTO_REPOSITORY_ROOT=http://puppet.yourmessagedelivered.com" >> /root/.bashrc ;
    /bin/echo "export PINTO_CREDS='-u deploy -p EhKyLkOvnA7JAbH7 '" >> /root/.bashrc ;
    /bin/echo "export PINTO_URL_CREDS=deploy:EhKyLkOvnA7JAbH7" >> /root/.bashrc ;
fi

source /root/.bashrc
/usr/bin/curl -L http://getpinto.stratopan.com | bash

if [[ ! `grep '/opt/local/pinto/etc/bashrc' /root/.bashrc | wc -l` > 0 ]] ; then 
    /bin/echo "source $HOME/etc/bashrc" >> /root/.bashrc ; 
fi

/bin/chmod u+x /root/.bashrc
source /root/.bashrc

if [[ -f $PINTO_HOME/.bashrc && ! `grep PINTO_URL_CREDS $PINTO_HOME/.bashrc | wc -l` > 0 ]] ; then 
    /bin/echo "export PINTO_HOME=/opt/local/pinto" >> $HOME/.bashrc ;
    /bin/echo "export PINTO_REPOSITORY_ROOT=http://puppet.yourmessagedelivered.com" >> $HOME/.bashrc ;
    /bin/echo "export PINTO_CREDS='-u deploy -p EhKyLkOvnA7JAbH7 '" >> $HOME/.bashrc ;
    /bin/echo "export PINTO_URL_CREDS=deploy:EhKyLkOvnA7JAbH7" >> $HOME/.bashrc ;
    /bin/echo "source $PINTO_HOME/etc/bashrc" >> $HOME/.bashrc ; 
fi

echo 0

