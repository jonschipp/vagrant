#!/bin/bash

## Variables
ARGC=$#
HOME=/root
ISO_DIR=/srv/iso
SYSLINUX=/usr/lib/syslinux/pxelinux.0
NIC=eth1
IP=$(ifconfig $NIC | grep 'inet addr:' | cut -d: -f2 | awk '{print $1}')
KERNEL="vmlinuz"
RAMDISK="initrd*"

# Installation notification
MAIL=$(which mail)
COWSAY=/usr/games/cowsay
IRCSAY=/usr/local/bin/ircsay
IRC_CHAN="#replace_me"
HOST=$(hostname -s)
LOGFILE=/root/islet_install.log
EMAIL=user@company.com

cd $HOME

usage() {
cat <<EOF

Download ISO and configure PXE server for new distribution installation.
Each option is required.

     Options:
     --os       Set OS os distribution name
     --url      URL of ISO image to configure
     --version  Set version
     --kernel   Set name of kernel (def: vmlinuz)
     --ramdisk  Set name of ramdisk (def: initrd*)
     --arch     Set arch if not listed in url as i386/amd64/x86_64
     --dir      Set directory of kernel in iso e.g. images/pxeboot (def: best guess)

Usage: $0 --os Ubuntu --version 14.0.1 --url http://releases.ubuntu.com/14.04/ubuntu-14.04.1-server-amd64.iso
EOF
}

argcheck() {
# if less than n argument
if [ $ARGC -lt $1 ]; then
 usage
 exit 1
fi
}

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

check_dir(){
  hi "$1 $FUNCNAME"
  [ -d $ISO_DIR ]                              || mkdir $ISO_DIR
  [ -d /srv/install ]                          || mkdir -p /srv/install
  [ -d /mnt/loop ]                             || mkdir /mnt/loop
  mount | grep -q /mnt/loop                    && umount /mnt/loop
}

download(){
  [ -e $ISO_DIR/$ISO ] || { wget -q -O $ISO_DIR/$ISO $URL || die "Failed to download iso!"; }
}

configuration(){
  [ -e /var/lib/tftpboot/$RELEASE/$DISTRO.menu ] && N=$(grep ^LABEL /var/lib/tftpboot/$RELEASE/$DISTRO.menu | wc -l)
  let N++
  mkdir -p /var/lib/tftpboot/$RELEASE || die "Failed to create dir!"
  mkdir -p /srv/install/$RELEASE      || die "Failed to create dir!"

  mount -o loop -t iso9660 $ISO_DIR/$ISO /mnt/loop 2>/dev/null || die "Unable to mount $ISO_DIR/$ISO!"

  for i in $DIR
  do
    [ -e /mnt/loop/$i/$KERNEL ] 2>/dev/null && cp /mnt/loop/$i/$KERNEL /var/lib/tftpboot/$RELEASE
    [ -e /mnt/loop/$i/$RAMDISK ] 2>/dev/null && cp /mnt/loop/$i/$RAMDISK /var/lib/tftpboot/$RELEASE
    file /var/lib/tftpboot/$RELEASE/$RAMDISK | grep -q gzip && gzip -d /var/lib/tftpboot/$RELEASE/$RAMDISK
  done

  cp -R /mnt/loop/* /srv/install/$RELEASE
  umount /mnt/loop && sleep 3

cat <<EOF >> /var/lib/tftpboot/$RELEASE/$DISTRO.menu
LABEL $N
        MENU LABEL $DISTRO $VERSION ($ARCH)
        KERNEL $RELEASE/$KERNEL
        APPEND $BOOT
        TEXT HELP
        Install $DISTRO $VERSION ($ARCH)
        ENDTEXT
EOF

cat <<EOF >> /var/lib/tftpboot/pxelinux.cfg/default
MENU BEGIN $DISTRO $VERSION $ARCH
MENU TITLE $DISTRO $VERSION $ARCH
        LABEL Previous
        MENU LABEL Previous Menu
        TEXT HELP
        Return to previous menu
        ENDTEXT
        MENU EXIT
        MENU SEPARATOR
        MENU INCLUDE $RELEASE/$DISTRO.menu
MENU END
EOF
}

argcheck 3

set -- $(getopt -n $0 -u -a --longoptions="url: os: version: kernel: ramdisk: arch: dir:" "h" "$@")
while [ $# -gt 0 ]
do
  case "$1" in
   --url) URL="$2"; shift;;
   --os)  DISTRO="$2"; shift;;
   --version) VERSION="$2"; shift;;
   --kernel) KERNEL="$2"; shift;;
   --initrd) RAMDISK="$2"; shift;;
   --arch) ARCH="$2"; shift;;
   --dir) DIR="$2"; shift;;
   --help|-h) usage; exit;;
  esac
  shift
done

  [ $ARCH ] ||
  { echo $URL | egrep -q 'x86_64|amd64' && ARCH=amd64 ; echo $URL | grep -q i[3-6]86 && ARCH=i386; ARCH=${ARCH:-unknown}; }

  RELEASE="$DISTRO/$VERSION/$ARCH"
  [ $DIR ] || DIR=$(echo {.,install/netboot/ubuntu-installer/$ARCH,install,install.*,isolinux,casper,images/pxeboot,boot/$ARCH,loader})
  ISO="$(basename $URL)"

  echo $RELEASE | egrep -i -q 'centos|fedora|redhat' &&
  BOOT="method=nfs:${IP}:/srv/install/$RELEASE initrd=${RELEASE}/initrd.img ramdisk_size=10000"
  echo $RELEASE | egrep -i -q 'debian|ubuntu|kali' &&
  BOOT="initrd=${RELEASE}/initrd root=/dev/nfs nfsroot=${IP}:/srv/install/$RELEASE"
  echo $RELEASE | egrep -i -q 'dban' &&
  BOOT="nuke=dwipe silent floppy=0,16,cmos"

check_dir "1.)"
download "2.)"
configuration "3.)"
hi "PXE boot configured for $RELEASE"
