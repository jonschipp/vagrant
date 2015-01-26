#!/bin/bash

## Variables
HOME=/root
VAGRANT=/home/vagrant
PACKAGES="cowsay apache2 tftpd-hpa inetutils-inetd isc-dhcp-server"
URL="${1:-http://releases.ubuntu.com/14.04/ubuntu-14.04.1-server-amd64.iso}"
ISO="$(basename $URL)"
KS=/var/www/html/ubuntu/install/ks.cfg
NIC=eth1
IP=$(ifconfig $NIC | grep 'inet addr:' | cut -d: -f2 | awk '{print $1}')
MASK=$(ifconfig $NIC | grep 'inet addr:' | cut -d: -f4 | awk '{ print $1 }')
BROADCAST=$(ifconfig $NIC | grep 'inet addr:' | cut -d: -f3 | awk '{ print $1 }')
# I'm too lazy to do the math to get net and range, presuming /24
NET=$(ifconfig $NIC | grep 'inet addr:' | cut -d: -f3 | awk '{ print $1 }' | cut -d . -f1-3)
BEGIN_RANGE=2
END_RANGE=254

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
  [ $MAIL ] && echo "$*" | mail -s "[vagrant] PXE install information on $HOST" $EMAIL
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
  [ $MAIL ] && echo "$*" | mail -s "[vagrant] PXE install information on $HOST" $EMAIL
  return 0
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
  hi "$1 $FUNCNAME"
  apt-get update -qq
  package_check $PACKAGES
}

configuration(){
  hi "$1 $FUNCNAME"
  grep -q "tftpboot" /etc/inetd.conf           || echo "tftp    dgram   udp    wait    root   \
    /usr/sbin/in.tftpd /usr/sbin/in.tftpd -s /var/lib/tftpboot" >> /etc/inetd.conf
  [ -e $HOME/ubuntu-14.04.1-server-amd64.iso ] || wget --progress=dot:mega -O $HOME/$ISO $URL
  [ -d /mnt/install ]                          || mount -o loop $HOME/$ISO /mnt
  [ -d /var/www/html/ubuntu/install ]          || mkdir -p /var/www/html/ubuntu/install
  cp -rf /mnt/* /var/www/html/ubuntu/
  [ -d /var/lib/tftpboot/ubuntu-installer ]    || cp -rf /mnt/install/netboot/* /var/lib/tftpboot/
  install -o root -g root -m 644 $VAGRANT/ks.cfg $KS
  install -o root -g root -m 644 $VAGRANT/tftpd-hpa  /etc/default/tftpd-hpa
  sed -i "s/replaceme/$IP/" $KS

cat <<EOF > /etc/dhcp/dhcpd.conf
ddns-update-style none;

# option definitions common to all supported networks...
option domain-name "example.org";
option domain-name-servers 8.8.8.8;

default-lease-time 600;
max-lease-time 7200;
allow bootp;
allow booting;
log-facility local7;

subnet ${NET}.0 netmask $MASK {
        range ${NET}.${BEGIN_RANGE} ${NET}.${END_RANGE};
        filename "pxelinux.0";
        option broadcast-address $BROADCAST;
        option routers $IP;
}
EOF

cat <<EOF > /var/www/html/ubuntu/install/preseed.cfg
d-i partman/confirm_write_new_label boolean true
d-i partman/choose_partition select finish
d-i partman/confirm boolean true
d-i partman/confirm_nooverwrite boolean true
d-i live-installer/net-image string
d-i live-installer/net-image string http://$IP/ubuntu/install/filesystem.squashfs
EOF

cat <<EOF > /var/lib/tftpboot/ubuntu-installer/amd64/boot-screens/syslinux.cfg
# D-I config version 2.0
default ubuntu-installer/amd64/boot-screens/vesamenu.c32
prompt 0
timeout 0
label Ubuntu-14.04.1-Server
        kernel ubuntu-installer/amd64/linux
	append vga=normal initrd=ubuntu-installer/amd64/initrd.gz ks=http://$IP/ubuntu/install/ks.cfg url=http://$IP/ubuntu/install/preseed.cfg ramdisk_size=16432 root=/dev/rd/0 rw  --
EOF
}

start_services(){
  hi "$1 $FUNCNAME"
  service isc-dhcp-server restart || die "Failed to start isc-dhcp-server"
  service tftpd-hpa restart       || die "Failed to start ftpd-hpa"
  service apache2 restart         || die "Failed to start apache2"
}

install_dependencies "1.)"
configuration "2.)"
start_services "3.)"
