#!/bin/bash
# Author: Jon Schipp <jonschipp@gmail.com>
# Written for Ubuntu Saucy and Trusty, should be adaptable to other distros.

## Variables
VAGRANT=/home/vagrant
HOME=/root
VERS=1.5.0
BUILD=/root/docker/bundles/$VERS-dev/dynbinary
[ -e /etc/redhat-release ] && OS=el
[ -e /etc/debian_version ] && OS=debian
[ "$OS" = "debian" ] && PACKAGES="docker git golang build-essential libdevmapper-dev golang-gosqlite-dev btrfs-tools uuid-dev libattr1-dev zlib1g-dev libacl1-dev e2fslibs-dev libblkid-dev liblzo2-dev"
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
    [ "$OS" = "debian" ] && apt-get install -qy $packages
    [ "$OS" = "el" ]     && yum install -qy $packages
  fi
}

install_dependencies(){
  hi "$1 $FUNCNAME\n"
  [ "$OS" = "debian" ] && apt-get update -qq
  [ "$OS" = "el" ]     && yum makecache -q
  #package_check $PACKAGES
  apt-get install -yq docker git golang build-essential libdevmapper-dev golang-gosqlite-dev \
    btrfs-tools uuid-dev libattr1-dev zlib1g-dev libacl1-dev e2fslibs-dev libblkid-dev liblzo2-dev
  apt-get install -yq asciidoc xmlto --no-install-recommends
}

install_btrfs-progs(){
  hi "$1 $FUNCNAME\n"
  if ! [ -f btrfs-progs ]
  then
    rm -rf btrfs-progs
    git clone https://kernel.googlesource.com/pub/scm/linux/kernel/git/mason/btrfs-progs || die "Clone of btrfs-progs repo failed"
    cd btrfs-progs
    make && make install
  fi

  cd $HOME
}

install_btrfs-progs(){
  hi "$1 $FUNCNAME\n"
  if ! [ -d btrfs-progs ] && ! [ -f /usr/local/bin/btrfsck ]
  then
    rm -rf btrfs-progs
    git clone https://kernel.googlesource.com/pub/scm/linux/kernel/git/mason/btrfs-progs || die "Clone of btrfs-progs repo failed"
    cd btrfs-progs
    make && make install || die "btrfs-progs build failed"
  fi
  cd $HOME
}

install_docker(){
  hi "  Installing Docker!\n"
  # Check that HTTPS transport is available to APT
  if [ ! -e /usr/lib/apt/methods/https ]; then
    apt-get update -qq
    apt-get install -qy apt-transport-https
    echo
  fi

  # Add the repository to your APT sources
  # Then import the repository key
  if [ ! -e /etc/apt/sources.list.d/docker.list ]
  then
    echo deb https://get.docker.io/ubuntu docker main > /etc/apt/sources.list.d/docker.list
    apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 36A1D7869245C8950F966E92D8576A8BA88D21E9
    echo
  fi

  # Install docker
  if ! command -v docker >/dev/null 2>&1
  then
    apt-get update -qq
    apt-get install -qy --no-install-recommends lxc-docker cgroup-lite
    #apt-get install -qy lxc-docker linux-image-extra-$(uname -r) aufs-tools
  fi
}

install_docker_dynamic(){
  hi "$1 $FUNCNAME\n"
  if ! [ -d docker ] && [ -f /usr/bin/docker ]
  then
    rm -rf docker
    git clone https://git@github.com/docker/docker || die "Clone of btrfs-progs repo failed"
    cd docker
    AUTO_GOPATH=1 ./project/make.sh dynbinary || die "Docker build falied!"
  fi
}

configuration(){
  hi "$1 $FUNCNAME\n"
  pgrep -lf docker 2>&1 >/dev/null && stop docker 2>/dev/null || true
  [ -f $BUILD/docker-$VERS-dev ] && install -m 755 -o root -g root $BUILD/docker-$VERS-dev /usr/bin/docker || die "File doesn't exist"
  [ -f $BUILD/dockerinit-$VERS-dev ] && install -m 755 -o root -g root $BUILD/dockerinit-$VERS-dev /var/lib/docker/init/dockerinit-$VERS-dev || die "File doesn't exist"
  [ -f $BUILD/dockerinit ] && install -m 755 -o root -g root $BUILD/dockerinit /usr/bin/dockerinit || "File doesn't exist"
  start docker || hi "A dynamically linked Docker has been installed"
}

install_dependencies "1.)"
install_btrfs-progs "2.)"
install_docker "3.)"
install_docker_dynamic "4.)"
ldd /usr/bin/docker 2>/dev/null | fgrep -q .so || configuration "5.)"
