#!/bin/bash
# Author: Jon Schipp <jonschipp@gmail.com>
# Written for Ubuntu Saucy and Trusty, should be adaptable to other distros.

## Variables
HOME=/root
PREFIX=/opt/cuckoo

# Installation notification
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
  echo "$*" | mail -s "[vagrant] Bro Sandbox install information on $HOST" $EMAIL
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
  echo "$*" | mail -s "[vagrant] Bro Sandbox install information on $HOST" $EMAIL
}

install_dependencies(){
  echo "$1 $FUNCNAME"
  apt-get update -qq
  # Required
  apt-get install -yq python python-sqlalchemy python-bson git
  # Recommended
  apt-get install -yq python-dpkt python-jinja2
  # Optional
  apt-get install -yq yara python-yara python-magic python-pymongo python-gridfs python-libvirt \
    python-bottle python-pefile python-chardet volatility tcpdump libcap2-bin
    # maec, pydeep
  # Virtualization
  if egrep -q '(vmx|svm)' /proc/cpuinfo; then
    apt-get install -yq qemu-kvm libvirt-bin ubuntu-vm-builder bridge-utils
  else
    echo "deb http://download.virtualbox.org/virtualbox/debian $(lsb_release -cs) contrib non-free" > /etc/apt/sources.list.d/virtualbox.list
    wget -q http://download.virtualbox.org/virtualbox/debian/oracle_vbox.asc -O - | sudo apt-key add -
    apt-get update && apt-get install -yq virtualbox-4.3 dkms
  fi
  }

configure_dependencies(){
  echo "$1 $FUNCNAME"
  if ! getcap /usr/sbin/tcpdump | grep -q cap_net_admin,cap_net_raw
  then
    setcap cap_net_raw,cap_net_admin=eip /usr/sbin/tcpdump
  fi
}

configure_users(){
  echo "$1 $FUNCNAME"
  getent passwd cuckoo 1>/dev/null 	  || adduser --disabled-password  --gecos "" --shell /bin/bash cuckoo
  getent group vboxusers | grep -q cuckoo || usermod -a -G vboxusers cuckoo 2>/dev/null
  getent group libvirtd  | grep -q cuckoo || usermod -a -G libvirtd cuckoo 2>/dev/null
  getent group kvm       | grep -q cuckoo || usermod -a -G kvm cuckoo 2>/dev/null
}

install_cuckoo(){
  echo "$1 $FUNCNAME"
  if ! [ -d $PREFIX ]
  then
    git clone git://github.com/cuckoobox/cuckoo.git $PREFIX || die "Clone of islet repo failed"
  fi
}

configure_cuckoo(){
  echo "$1 $FUNCNAME"
  #sed -i '/^machinery/s/virtualbox/kvm/' $PREFIX/conf/cuckoo.conf
  sed -i '/^memory_dump/s/off/on/' $PREFIX/conf/cuckoo.conf
  sed -i '/^terminate_processes/s/off/on/' $PREFIX/conf/cuckoo.conf
  sed -i '/^freespace/s/64/512/' $PREFIX/conf/cuckoo.conf
  sed -i '/^ip =/s/192\.168\.56\.1/0.0.0.0/' $PREFIX/conf/cuckoo.conf
  sed -i '/^resolve_dns/s/on/off/' $PREFIX/conf/cuckoo.conf
  sed -i '/^# bpf/s/^#//' $PREFIX/conf/auxiliary.conf
}

install_dependencies "1.)"
configure_dependencies "2.)"
configure_users "3.)"
install_cuckoo "4.)"
configure_cuckoo "5.)"
