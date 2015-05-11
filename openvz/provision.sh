#!/bin/bash
# Author: Jon Schipp <jonschipp@gmail.com>
# Written for Ubuntu Saucy and Trusty, should be adaptable to other distros.

## Variables
VAGRANT=/home/vagrant
HOME=/root
[ -e /etc/redhat-release ] && OS=el && export PKG_CONFIG_PATH="/usr/local/lib/pkgconfig:/lib64/pkgconfig/"
[ -e /etc/debian_version ] && OS=debian
[ "$OS" = "debian" ] && PACKAGES="vzkernel"
[ "$OS" = "el" ] && PACKAGES="wget vzkernel vzctl vzquota ploop"

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
  [ -f /etc/yum.repos.d/openvz.repo ] || wget -P /etc/yum.repos.d/ http://ftp.openvz.org/openvz.repo
  rpm --import http://ftp.openvz.org/RPM-GPG-Key-OpenVZ
  package_check $PACKAGES
}

configuration(){
  hi "$1 $FUNCNAME\n"
cat <<EOF >> /etc/sysctl.conf
# On Hardware Node we generally nee  d
# packet forwarding enabled and pro  xy arp disabled
net.ipv4.ip_forward = 1
net.ipv6.conf.default.forwarding =   1
net.ipv6.conf.all.forwarding = 1
net.ipv4.conf.default.proxy_arp = 0

# Enables source route verification
net.ipv4.conf.all.rp_filter = 1

# Enables the magic-sysrq key
kernel.sysrq = 1

# We do not want all our interfaces to send redirects
net.ipv4.conf.default.send_redirects = 1
net.ipv4.conf.all.send_redirects = 0
EOF
echo "options nf_conntrack ip_conntrack_disable_ve0=0" > /etc/modprobe.d/openvz.conf
echo -e "modprobe vzcpt\nmodprobe vzrst" > /etc/rc.modules

}

install_dependencies "1.)"
configuration "2.)"
