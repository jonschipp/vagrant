#!/bin/bash
# Author: Jon Schipp <jonschipp@gmail.com>
# Written for Ubuntu Saucy and Trusty, should be adaptable to other distros.

## Variables
VAGRANT=/home/vagrant
HOME=/root
DAQ=2.0.4
PACKAGES="cowsay git build-essential checkinstall automake autoconf pkg-config libtool libpcre3-dev libpcre3 libdumbnet1 libdumbnet-dev libesmtp-dev libpcap-dev libgeoip-dev libjson0 libjson0-dev libcurl4-openssl-dev"
[ -e /etc/redhat-release ] && OS=el
[ -e /etc/debian_version ] && OS=debian

# Installation notification
MAIL=$(which mail)
COWSAY=/usr/games/cowsay
IRCSAY=/usr/local/bin/ircsay
IRC_CHAN="#replace_me"
HOST=$(hostname -s)
LOGFILE=/root/islet_install.log
EMAIL=user@company.com

cd $HOME

function die {
  if [ -f ${COWSAY:-none} ]; then
    $COWSAY -d "$*"
  else
    echo "$*"
  fi
  if [ -f $IRCSAY ]; then
    ( set +e; $IRCSAY "$IRC_CHAN" "$*" 2>/dev/null || true )
  fi
  [ $MAIL ] && echo "$*" | mail -s "[vagrant] Sagan install information on $HOST" $EMAIL
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
  [ $MAIL ] && echo "$*" | mail -s "[vagrant] Sagan install information on $HOST" $EMAIL
}

number_of_packages(){ package_count="$#"; }

package_check(){
  local packages=$@
  local count=0
  # Count number of items in packages variable
  number_of_packages $packages

  # Format items for egrep query
  pkg_list=$(echo $packages | sed 's/ /|  /g')

  # Count number of packages installed from list
  [ "$OS" = "debian" ] && count=$(dpkg -l | egrep "  $pkg_list" | wc -l)
  [ "$OS" = "el" ]     && count=$(yum list installed | egrep "$pkg_list" | wc -l)

  if [ $count -ge $package_count ]
  then
    return 0
  else
    echo "Installing packages for function!"
    [ "$OS" = "debian" ] && yum install -qy $packages
    [ "$OS" = "el" ]     && apt-get install -qy $packages
  fi
}

install_dependencies(){
  hi "$1 $FUNCNAME\n"
  [ "$OS" = "debian" ] && apt-get update -qq
  [ "$OS" = "el" ]     && yum makecache -q
  package_check $PACKAGES
  [ -f /usr/local/lib/libestr.so.0.0.0 ] || (git clone https://github.com/rsyslog/libestr && cd libestr && \
    autoreconf -vfi && ./configure && make && make install && ldconfig)
  [ -f /usr/local/lib/liblognorm.so.1.0.0 ] || (git clone https://github.com/rsyslog/liblognorm && cd liblognorm && \
    autoreconf -vfi && ./configure --disable-docs && make install && ldconfig)
}

install_sagan(){
  hi "$1 $FUNCNAME\n"
  if ! [ -f /usr/local/sbin/sagan ]
  then
    rm -rf sagan
    git clone http://github.com/beave/sagan || die "Clone of sagan repo failed"
    cd sagan
    ./configure --enable-geoip --enable-esmtp --enable-libpcap && make && make install
  fi

  cd $HOME

  if ! [ -d /usr/local/etc/sagan-rules ]
  then
    git clone http://github.com/beave/sagan-rules /usr/local/etc/sagan-rules || die "Clone of sagan-rules repo failed"
  fi

  cd $HOME
}

configuration(){
  hi "$1 $FUNCNAME\n"
  getent passwd sagan 1>/dev/null || useradd sagan --shell /sbin/nologin --home /
  getent group sagan | grep -q syslog || gpasswd -a syslog sagan
  chown -R sagan:sagan /var/log/sagan /var/run/sagan
  chown -R sagan:sagan /usr/local/etc/
  [ -p /var/run/sagan.fifo ] || mkfifo /var/run/sagan.fifo
  chown sagan:sagan /var/run/sagan.fifo
  chmod 660 /var/run/sagan.fifo
  [ -e /etc/rsyslog.d/sagan.conf ] || (install -o root -g root -m 644 $VAGRANT/rsyslog-sagan.conf \
    /etc/rsyslog.d/sagan.conf && restart rsyslog)
  [ -e /etc/init/sagan.conf ] || (install -o root -g root -m 644 $VAGRANT/sagan.upstart \
    /etc/init/sagan.conf && start sagan)
}

install_daq(){
  hi "$1 $FUNCNAME\n"
  if ! [ -f /usr/local/lib/libdaq.so.2.0.4 ]
  then
    package_check bison flex
    rm -fr daq-${DAQ}*
    wget https://www.snort.org/downloads/snort/daq-${DAQ}.tar.gz || die "Failed to download daq-${DAQ}"
    tar zxf daq-${DAQ}.tar.gz
    cd daq-${DAQ}
    ./configure && make && make install || die "DAQ ${DAQ} failed to install"
  fi
  cd $HOME
}

install_barnyard(){
  # Get dependency
  install_daq

  hi "$1 $FUNCNAME\n"
  if ! [ -f /usr/local/bin/barnyard2 ]
  then
    rm -rf barnyard2
    package_check libmysqlclient-dev
    ln -f -s /usr/include/dumbnet.h /usr/include/dnet.h
    git clone https://github.com/firnsy/barnyard2 || die "Clone of barnyard2 repo failed"
    cd barnyard2
    ./autogen.sh && ./configure --with-mysql --with-mysql-libraries=/usr/lib/x86_64-linux-gnu && make && make install || die "Barnyard2 failed to install"
  fi
  [ -d /var/log/barnyard2 ] || mkdir /var/log/barnyard2
  [ -e /usr/local/etc/barnyard2-sagan.conf ] || install -o root -g root -m 600 $VAGRANT/barnyard2-sagan.conf /usr/local/etc/barnyard2-sagan.conf
  [ -e /etc/init/barnyard2 ] || install -o root -g root -m 644 $VAGRANT/barnyard2.upstart /etc/init/barnyard2.conf
  cd $HOME
}

install_dependencies "1.)"
install_sagan "2.)"
install_barnyard "3.)"
configuration "4.)"

pgrep sagan 1>/dev/null && hi "Installation successful! Sagan is running $(pidof sagan)..."
