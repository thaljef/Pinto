#!/bin/bash

# Copyright 2013 Hugh Esco <hesco@campaignfoundations.com>

set -e 

if [[ ! `grep PINTO_HOME /root/.bashrc | wc -l` > 0 ]] ; then 
	echo "export PINTO_HOME=/opt/local/pinto" >> /root/.bashrc ;
fi

if [[ ! `grep PINTO_REPOSITORY_ROOT /root/.bashrc | wc -l` > 0 ]] ; then 
	echo "export PINTO_REPOSITORY_ROOT=/var/pinto" >> /root/.bashrc ;
fi

source /root/.bashrc
curl -L http://getpinto.stratopan.com | bash
echo "source $PINTO_HOME/etc/bashrc" >> /root/.bashrc
source /root/.bashrc

pinto init 
cp $PINTO_HOME/etc/init.d/pintod.debian /etc/init.d/pintod

