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
  if [ -f $IRCSAY ]; then
    ( set +e; $IRCSAY "$IRC_CHAN" "$*" 2>/dev/null || true )
  fi
  echo "$*" | mail -s "[vagrant] Sagan install information on $HOST" $EMAIL
  exit 1
}

function hi {
  if [ -f ${COWSAY:-none} ]; then
    $COWSAY "$*"
  else
    echo "$*"
  fi
  if [ -f $IRCSAY ]; then
    ( set +e; $IRCSAY "$IRC_CHAN" "$*" 2>/dev/null || true )
  fi
  echo "$*" | mail -s "[vagrant] Sagan install information on $HOST" $EMAIL
}

install_dependencies(){
  printf "$1 $FUNCNAME\n"
  apt-get update -qq
  apt-get install -y git build-essential checkinstall automake autoconf \
                       pkg-config libtool libpcre3-dev libpcre3 libdumbnet1 \
                       libdumbnet-dev libesmtp-dev libpcap-dev libgeoip-dev \
                       libjson0 libjson0-dev libcurl4-openssl-dev
  ! [ -d libestr ] && git clone https://github.com/rsyslog/libestr && cd libestr &&
              autoreconf -vfi && ./configure && make && make install && ldconfig
  ! [ -d liblognorm ] && git clone https://github.com/rsyslog/liblognorm && cd liblognorm &&
              autoreconf -vfi && ./configure --disable-docs && make install && ldconfig
}

install_islet(){
  printf "$1 $FUNCNAME\n"
  if ! [ -d sagan ]
  then
    git clone http://github.com/beave/sagan || die "Clone of sagan repo failed"
    cd sagan
    ./configure --enable-geoip --enable-esmtp --enable-libpcap && make && make install
  fi

  if ! [ -d /usr/local/etc/sagan-rules ]
  then
    git clone http://github.com/beave/sagan-rules || die "Clone of sagan-rules repo failed"
  fi
}

configuration() {
  printf "$1 $FUNCNAME\n"
  chown -R sagan:sagan /var/log/sagan /var/run/sagan
  chown -R sagan:sagan /usr/local/etc/
  mkfifo /var/run/sagan.fifo
  chown sagan:sagan /var/run/sagan.fifo
  chmod 660 /var/run/sagan.fifo
  getent group sagan | grep -q syslog || gpasswd -a -G syslog sagan

  echo -e '#Sagan template\n$template sagan,"%fromhost-ip%|%syslogfacility-text%|%syslogpriority-text%|%syslogseverity-text%|%syslogtag%|%timegenerated:1:10:date-rfc3339%|%timegenerated:12:19:date-rfc3339%|%programname%|%msg%\\n"\n*.*     |/var/run/sagan.fifo;sagan\n' > /etc/rsyslog.d/sagan.conf
}

install_dependencies "1.)"
install_sagan "2.)"
configuration "3.)"
