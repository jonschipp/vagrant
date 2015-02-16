#!/bin/bash
# We start here
HOME=/root
VAGRANT=/home/vagrant
ARG=${1:-0}
BPF=0
COWSAY=/usr/games/cowsay
cd $HOME

function die {
  $COWSAY -d "$* MooOoOOoo"
  exit 1
}

function hi {
  $COWSAY "$*"
}

function install_dependencies {
  # Install dependencies
  apt-get update -qq
  apt-get -qy install cowsay git vim ethtool iotop sysstat cowsay nmap dstat tshark htop

  # Xen Project
  apt-get -qy install bridge-utils xen-hypervisor-amd64 xen-tools

  # Ganeti
  apt-get -qy install ganeti kpartx dump drbd8-utils ganeti-htools fai-client \
  libghc-json-dev libghc-network-dev libghc-parallel-dev libghc-curl-dev ghc \
  linux-image-extra-virtual lvm2 iproute iputils-arping make m4 ndisc6 \
  python python-openssl openssl python-pyparsing python-simplejson python-bitarray \
  python-pyinotify python-pycurl python-ipaddr socat fping python-paramiko python-psutil \
  qemu-utils python-setuptools python-dev python-ipaddr

  hi "Dependencies installed!"

  # Unsure, used for compiling ganeti
  #apt-get install build-essential cabal-install dpkg-dev fabric g++ g++-4.8 \
  #  libalgorithm-diff-perl libalgorithm-diff-xs-perl libalgorithm-merge-perl \
  #  libdpkg-perl libexpat1-dev libfile-fcntllock-perl libpython-dev socat \
  #  libpython2.7-dev python-colorama python-dev python-distlib python-html5lib \
  #  python-nose python-pip python-setuptools python2.7-dev ghc libghc-json-dev \
  #  libghc-network-dev libghc-parallel-dev libghc-utf8-string-dev libghc-curl-dev libghc-hslogger-dev \
  #  libghc-crypto-dev libghc-text-dev libghc-hinotify-dev libghc-regex-pcre-dev libpcre3-dev \
  #  libghc-attoparsec-dev libghc-vector-dev libghc-zlib-dev libghc-base64-bytestring-dev \
  #  libghc-lens-dev libghc-lifted-base-dev m4 python-pyparsing python-pyinotify python-bitarray \
  #  python-ipaddr
  #depmod -a
  #cabal update
  #cabal install json network parallel utf8-string curl hslogger \
  #  Crypto text hinotify==0.3.2 regex-pcre attoparsec vector base64-bytestring \
  #  lifted-base==0.2.0.3 lens==3.10
}


function install_ganeti {
  # Compiling and installing
  wget http://downloads.ganeti.org/releases/2.12/ganeti-2.12.0.tar.gz
  tar zxf ganeti-2.12.0.tar.gz
  cd ganeti-2.12.0/
  ./configure --localstatedir=/var --sysconfdir=/etc && make && make install
  hi "Ganeti installed!"
  cd $HOME
}

function install_ganeti_debootstrap {
  url="https://launchpad.net/ubuntu/+archive/primary/+files/ganeti-instance-debootstrap_0.14-2_all.deb"
  deb=$(basename $url)
  cd $HOME
  [ -e $deb ] || { wget $url || die "Failed to download ganeti-instance-debootstrap"; }
  dpkg -l | grep -q "ganeti-instance-debootstrap.*0.14-2" || dpkg --install $deb
  hi "Ganeti Debootstrap installed!"
}

function install_snf_image {
  apt-get install -y software-properties-common
  apt-add-repository ppa:grnet/synnefo
  echo -e "deb http://apt.dev.grnet.gr trusty/\ndeb-src http://apt.dev.grnet.gr trusty/" >> /etc/apt/sources.list
  apt-get update
  apt-get install -y snf-image
}

function system_configuration {
  cd $HOME
  # System and network configuration
  #! grep -s -q dom0_mem=512 /etc/default/grub.d/xen.cfg && \
  #sed -i '1s/^/GRUB_CMDLINE_XEN_DEFAULT="dom0_mem=512M,max:512M dom0_max_vcpus=1 dom0_vcpus_pin=1"/' /etc/default/grub.d/xen.cfg && \
  #   update-grub2
  echo "service ssh restart" > /etc/init.d/ssh # Bug: https://bugs.launchpad.net/ubuntu/+source/ganeti/+bug/1308571
  echo "${HOSTNAME}.test" > /etc/hostname
  sed -i -e '/#autoballoon/s/^#//' -e '/^autoballoon/s/auto/off/2' /etc/xen/xl.conf
  sed -i '/dowait 120/d'  /etc/init/cloud-init-nonet.conf
  sed -i 's/dowait/10/2' /etc/init/cloud-init-nonet.conf
  sed -i '/sleep 40/d' /etc/init/failsafe.conf
  sed -i '/sleep 59/d' /etc/init/failsafe.conf
  ln -f -s /boot/vmlinuz-$(uname -r) /boot/vmlinuz-3-xenU
  ln -f -s /boot/initrd.img-$(uname -r) /boot/initrd-3-xenU
  grep -q xen_blkfront /etc/initramfs-tools/modules || { echo "xen_blkfront" >> /etc/initramfs-tools/modules && update-initramfs -u; }

  [ -e $VAGRANT/interfaces* ] && install -o root -g root -m 644 $VAGRANT/interfaces* /etc/network/interfaces.d/xen.cfg
  [ -e $VAGRANT/hosts ] && install -o root -g root -m 644 $VAGRANT/hosts /etc/hosts
  [ -e $VAGRANT/modules ] && install -o root -g root -m 644 $VAGRANT/modules /etc/modules
  [ -e $VAGRANT/xend-config.sxp ] && install -o root -g root -m 644 $VAGRANT/xend-config.sxp /etc/xen/xend-config.sxp
  [ -e $VAGRANT/lvm.conf ] && install -o root -g root -m 644 $VAGRANT/lvm.conf /etc/xen/lvm.conf

  ssh_configuration
  ufw disable
  lvm_configuration
  hi "Everything ran! Time for a reboot"
}

function ssh_configuration {
SSH=$HOME/.ssh
mkdir -m 700 -p $SSH
cat <<EOF > $SSH/known_hosts
|1|3f5uzy9DiJxk04xeaDsbljUHPQ4=|LZ2CUsaUBiUtpMjKSv64XOpw8Yk= ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBHxD2nBigtIMmwyMYKJKp5Oz+XMAxWZw4mEnXIKlqR7bRjQZxD6U4nakPlB9Y9kR4rgNTYBDLd5Sx+Aw6y1te1M=
|1|sdJBNEBCk0YZ8kVdTuqH1AHb0ro=|SbLxDLwSdGyqwSWFMCIC+0NbSwc= ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBHxD2nBigtIMmwyMYKJKp5Oz+XMAxWZw4mEnXIKlqR7bRjQZxD6U4nakPlB9Y9kR4rgNTYBDLd5Sx+Aw6y1te1M=
EOF
cat <<EOF > $SSH/id_dsa.pub
ssh-dss AAAAB3NzaC1kc3MAAACBAIHNYzf38A+PHIpSYd7B78XAUnnqTWtxGON4LRCcGOk4aDfY5FF7B5v5ywLBb6HBQZ0oVur/cW87r0Cj9yP56haZtq09JIBAywWpIKnWkE5+gzs62IDq7mXxvmx3sNArpvbGfzCV9yY3hdeEHqYtwI6fOygb1hRR52XfoIso7EADAAAAFQCSxXJGVzoHeuGTR49pYRKyaNjVjwAAAIBJSo/c9iBCIKvrKUHbnA2EohG4B1K6PFUX6OLCeqVlzDZHwaYXHDQnrSSOmqK8RyttsGhWEC16kp8bc/ldm/xQuGmaXqqtk9mS9MGDAeJgXx3lD5XkIYbrypSGSuVG5UtC6nFKxbWklEF0rSvm+yDnyaoKlYkA6+52ngx85bT10wAAAIBh7YhYuy6YHilCcbkAa0UvVu6Lds+nqnh+jdc4A+Phijt3i8q6/yDJj0WhM9TVgo7TKzbe7/SpzU98gdY2bOxZd1xNjFyquVEP92+LAm+s/OCbU7n3g43EWKfq5M6fpIPtXzEOFMRuOncg7EEGywDz3cyaCD+mtuI6hF3beG0ntA== root@xen-node1.test
EOF
cat <<EOF >> $SSH/authorized_keys
ssh-dss AAAAB3NzaC1kc3MAAACBAIHNYzf38A+PHIpSYd7B78XAUnnqTWtxGON4LRCcGOk4aDfY5FF7B5v5ywLBb6HBQZ0oVur/cW87r0Cj9yP56haZtq09JIBAywWpIKnWkE5+gzs62IDq7mXxvmx3sNArpvbGfzCV9yY3hdeEHqYtwI6fOygb1hRR52XfoIso7EADAAAAFQCSxXJGVzoHeuGTR49pYRKyaNjVjwAAAIBJSo/c9iBCIKvrKUHbnA2EohG4B1K6PFUX6OLCeqVlzDZHwaYXHDQnrSSOmqK8RyttsGhWEC16kp8bc/ldm/xQuGmaXqqtk9mS9MGDAeJgXx3lD5XkIYbrypSGSuVG5UtC6nFKxbWklEF0rSvm+yDnyaoKlYkA6+52ngx85bT10wAAAIBh7YhYuy6YHilCcbkAa0UvVu6Lds+nqnh+jdc4A+Phijt3i8q6/yDJj0WhM9TVgo7TKzbe7/SpzU98gdY2bOxZd1xNjFyquVEP92+LAm+s/OCbU7n3g43EWKfq5M6fpIPtXzEOFMRuOncg7EEGywDz3cyaCD+mtuI6hF3beG0ntA== root@xen-node1.test
EOF
cat <<EOF > $SSH/id_dsa
-----BEGIN DSA PRIVATE KEY-----
MIIBugIBAAKBgQCBzWM39/APjxyKUmHewe/FwFJ56k1rcRjjeC0QnBjpOGg32ORR
eweb+csCwW+hwUGdKFbq/3FvO69Ao/cj+eoWmbatPSSAQMsFqSCp1pBOfoM7OtiA
6u5l8b5sd7DQK6b2xn8wlfcmN4XXhB6mLcCOnzsoG9YUUedl36CLKOxAAwIVAJLF
ckZXOgd64ZNHj2lhErJo2NWPAoGASUqP3PYgQiCr6ylB25wNhKIRuAdSujxVF+ji
wnqlZcw2R8GmFxw0J60kjpqivEcrbbBoVhAtepKfG3P5XZv8ULhpml6qrZPZkvTB
gwHiYF8d5Q+V5CGG68qUhkrlRuVLQupxSsW1pJRBdK0r5vsg58mqCpWJAOvudp4M
fOW09dMCgYBh7YhYuy6YHilCcbkAa0UvVu6Lds+nqnh+jdc4A+Phijt3i8q6/yDJ
j0WhM9TVgo7TKzbe7/SpzU98gdY2bOxZd1xNjFyquVEP92+LAm+s/OCbU7n3g43E
WKfq5M6fpIPtXzEOFMRuOncg7EEGywDz3cyaCD+mtuI6hF3beG0ntAIUcLGhWozZ
wsMfG8jpCFr1RPEGzZs=
-----END DSA PRIVATE KEY-----
EOF
chmod 0600 $SSH/*
}

function lvm_configuration {
  if [ -b /dev/sdb ]; then
    pvcreate /dev/sdb
    vgcreate ganeti /dev/sdb
  fi
}

if ! which xen 2>&1 > /dev/null; then
 	install_dependencies
        install_ganeti_debootstrap
        #install_snf_image # 3rd party tool
        #install_instance_image # 3rd party tool
        system_configuration
fi

cat <<EOF
Run these commands on node1 to create the cluster:
$ vagrant ssh node1
$ gnt-cluster init --enabled-hypervisors=xen-pvm --hypervisor-parameters xen-pvm:xen_cmd=xl --vg-name ganeti --nic-parameters link=xenbr0 \
--master-netdev xenbr0 --secondary-ip 192.168.1.10 --no-ssh-init xen-cluster.test
$ gnt-node add -v -d --no-ssh-key-check --master-capable=yes --vm-capable=yes --secondary-ip 192.168.1.20 xen-node2.test
Run VM cluster tests on node1:
$ /usr/lib/ganeti/tools/burnin -v -d -o debootstrap+default --disk-size=1024m --mem-size=128m -p instance1
EOF
#--backend-parameters vcpus=1,minmem=64,maxmem=256M,always_failover=true

reboot
