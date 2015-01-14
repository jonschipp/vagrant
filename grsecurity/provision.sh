#!/bin/bash
# Author: Jon Schipp <jonschipp@gmail.com>
# Written for Ubuntu Saucy and Trusty, should be adaptable to other distros.

## Variables
HOME=/root
VAGRANT=/home/vagrant
PACKAGES="cowsay build-essential flex bison ncurses-dev gcc-4.8-plugin-dev"
VERS="${1:-3.14.28}"
PATCH="grsecurity-3.0-${VERS}-201501120819.patch"
KERNEL="linux-${VERS}.tar.xz"
DIR=${KERNEL%.*.*}
GRADM="gradm-3.0-201408301734.tar.gz"
PAXCTLD="paxctld_1.0-2_amd64.deb"
GDIR=${GRADM%.*.*}
CPUS=$(nproc)

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
  [ $MAIL ] && echo "$*" | mail -s "[vagrant] Bro Sandbox install information on $HOST" $EMAIL
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
  [ $MAIL ] && echo "$*" | mail -s "[vagrant] Bro Sandbox install information on $HOST" $EMAIL
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
  count=$(dpkg -l | egrep "  $pkg_list" | wc -l)

  if [ $count -ge $package_count ]
  then
    return 0
  else
    echo "Installing packages for function!"
    apt-get install -qy $packages
  fi
}

install_dependencies(){
  echo "$1 $FUNCNAME"
  apt-get update -qq
  package_check $PACKAGES
  [ -f $KERNEL ] || { wget --progress=dot:mega https://www.kernel.org/pub/linux/kernel/v3.x/$KERNEL || die "Download of kernel failed"; }
  [ -f $PATCH  ] || { wget --progress=dot:mega https://grsecurity.net/stable/$PATCH || die "Download of patch failed"; }
  [ -d $DIR ]    || tar xf $KERNEL
  cd $HOME/$DIR
  patch -p1 < $HOME/$PATCH || die "Patch failed to apply!"
  [ -e $VAGRANT/config ] && install -o root -g root $VAGRANT/config $HOME/$DIR/.config
}

compile_kernel(){
  echo "$1 $FUNCNAME"
  make -j $CPUS         || die "Failed to build kernel!"
  make -j $CPUS modules || die "Failed to build kernel modules!"
  make modules_install  || die "Failed to install kernel modules!"
  { make install && hi "Linux kernel $KERNEL installed!"; } || die "Failed to install kernel!"
}

install_gradm(){
  echo "$1 $FUNCNAME"
  [ -f $GRADM ] || { wget https://grsecurity.net/stable/$GRADM || die "Download of gradm admin tool failed"; }
  [ -d $GDIR ]  || tar zxf $KERNEL
  cd $HOME/$GDIR
  make && make install || die "Failed to compile gradm!"
}

install_paxctld(){
  echo "$1 $FUNCNAME"
  wget --quiet https://grsecurity.net/paxctld/$PAXCTLD
  [ -e $PAXCTLD ] && dpkg --install $PAXCTLD
}

install_dependencies "1.)"
compile_kernel "2.)"
install_gradm "3.)"
install_paxctld "4.)"

hi "All is well! Rebooting into new kernel" && reboot
