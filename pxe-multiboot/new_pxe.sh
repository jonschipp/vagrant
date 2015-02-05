#!/bin/bash

## Variables
ARGC=$#
HOME=/root
PXE_DIR=/srv/pxe
TFTPROOT=/var/lib/tftpboot

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

Download PXE archive and extract in tftproot
Each option is required.

     Options:
     --url      Location of PXE tar.gz archive
     --path     tftp root path (def: /var/lib/tftpboot)

Usage: $0 -url http://repo.kali.org/kali/dists/kali/main/installer-i386/current/images/netboot/netboot.tar.gz
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
  [ -d $PXE_DIR ]                              || mkdir $PXE_DIR
  [ -e $PXE_DIR/pxelinux.0 ]                   && mv $TFTPROOT ${TFTPROOT}-${RANDOM}
  [ -d $TFTPROOT ]                             || mkdir $TFTPROOT
}

download(){
  [ -e $PXE_DIR/$ARCHIVE ] || { wget -q -O $PXE_DIR/$ARCHIVE $URL || die "Failed to download archive!"; }
}

configuration(){
  file $PXE_DIR/$ARCHIVE | grep -q gzip && tar zxf $PXE_DIR/$ARCHIVE -C $TFTPROOT || die "$ARCHIVE is not a tar gzip file"
  pkill tftpd
  service tftpd-hpa start         || die "Failed to start ftpd-hpa"
}

argcheck 1

set -- $(getopt -n $0 -u -a --longoptions="url: path:" "h" "$@")
while [ $# -gt 0 ]
do
  case "$1" in
   --url) URL="$2"; shift;;
   --path) TFTPROOT="$2"; shift;;
   --help|-h) usage; exit;;
  esac
  shift
done

ARCHIVE="$(basename $URL)"

check_dir "1.)"
download "2.)"
configuration "3.)"
hi "PXE boot configured for $ARCHIVE"
