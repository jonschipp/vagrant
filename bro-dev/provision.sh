#!/bin/bash
# Author: Jon Schipp <jonschipp@gmail.com>
# Written for Ubuntu Saucy and Trusty, should be adaptable to other distros.

## Variables
VAGRANT=/home/vagrant
HOME=/root
DAQ=2.0.4
[ -e /etc/redhat-release ] && OS=el && export PKG_CONFIG_PATH="/usr/local/lib/pkgconfig:/lib64/pkgconfig/"
[ -e /etc/debian_version ] && OS=debian
[ "$OS" = "debian" ] && PACKAGES="cmake make gcc g++ flex bison libpcap-dev libssl-dev python-dev swig zlib1g-dev libmagic-dev"
[ "$OS" = "el" ] && PACKAGES=""

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
  [ $MAIL ] && echo "$*" | mail -s "[vagrant] bro-dev install information on $HOST" $EMAIL
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
  [ $MAIL ] && echo "$*" | mail -s "[vagrant] bro-dev install information on $HOST" $EMAIL
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
    [ "$OS" = "debian" ] && apt-get install -qy $packages
    [ "$OS" = "el" ]     && yum install -qy $packages
  fi
}

install_dependencies(){
  hi "$1 $FUNCNAME\n"
  [ "$OS" = "debian" ] && apt-get update -qq
  [ "$OS" = "el" ]     && yum makecache -q
  package_check $PACKAGES
  apt-get -y install cmake make gcc g++ flex bison \
    libpcap-dev libssl-dev python-dev swig zlib1g-dev libmagic-dev && hi "Dependencies installed!"
}

function install_extras {
  # Install extras
  apt-get -y install git libgeoip-dev gawk sendmail curl tcpreplay cowsay

  if [ ! -f /usr/share/GeoIP/GeoIPCity.dat ]; then
    wget --progress=dot:mega http://geolite.maxmind.com/download/geoip/database/GeoLiteCity.dat.gz
    gunzip GeoLiteCity.dat.gz
    mv GeoLiteCity.dat /usr/share/GeoIP/GeoIPCity.dat && hi "GeoIP database installed"
  fi
}

install_bro(){
  hi "$1 $FUNCNAME\n"
  cd $HOME
  if ! [ -d bro ]
  then
    git clone --recursive git://git.bro.org/bro || die "Clone of bro repo failed"
  fi
  cd $HOME
}

install_binpac_quickstart(){
  hi "$1 $FUNCNAME\n"
  cd $HOME
  if ! [ -d binpac_quickstart ]
  then
    git clone https://github.com/grigorescu/binpac_quickstart || die "Clone of binpac_quickstart repo failed"
  fi
  cd $HOME
}

configuration(){
  hi "$1 $FUNCNAME\n"
}

install_dependencies "1.)"
install_extras "2.)"
install_bro "3.)"
install_binpac_quickstart "4.)"
configuration "4.)"
