#!/bin/bash
# Author: Jon Schipp <jonschipp@gmail.com>
# Written for Ubuntu Saucy and Trusty, should be adaptable to other distros.

## Variables
HOME=/root
cd $HOME

# Installation notification
COWSAY=/usr/games/cowsay
IRCSAY=/usr/local/bin/ircsay
IRC_CHAN="#replace_me"
HOST=$(hostname -s)
LOGFILE=/root/islet_install.log
EMAIL=user@company.com

function die {
  if [ -f ${COWSAY:-none} ]; then
    $COWSAY -d "$*"
  else
    echo "$*"
  fi
  exit 1
}

function hi {
  if [ -f ${COWSAY:-none} ]; then
    $COWSAY "$*"
  else
    echo "$*"
  fi
}

install_dependencies(){
  hi "$1 $FUNCNAME"
  export DEBIAN_FRONTEND=noninteractive
  apt-get update -qq
  add-apt-repository ppa:mrazavi/openvas
  apt-get update
  apt-get install -yq openvas9 sqlite3
  greenbone-nvt-sync
  greenbone-scapdata-sync
  greenbone-certdata-sync
}

start_services(){
  hi "$1 $FUNCNAME"
  service openvas-scanner restart
  service openvas-manager restart
}

install_dependencies "1.)"
start_services "2.)"

echo -e "\nTry it out: https://admin:admin@localhost:4000"
