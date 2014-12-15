  #!/bin/bash

# We start here
HOME=/home/vagrant
ARG=${1:-0}
# Get latest stable linux kernel
LATEST_STABLE_KERNEL_URL=http://www.kernel.org/$(wget -O - https://www.kernel.org 2>/dev/null | grep -A 5 "Latest Stable Kernel" | awk -F '[""]' '/\.xz/ { print $2 }')
KERNEL=$(echo $LATEST_STABLE_KERNEL_URL | sed 's/.*\///;s/\.tar.*$//')
CURRENT=$(echo $(uname -r) | sed 's/-.*//;s/^/linux-/')
UPDATE=$ARG
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
    apt-get -y install cowsay git vim ethtool iotop sysstat cowsay nmap dstat tshark htop

    # Xen Project
    apt-get -y install bridge-utils xen-hypervisor-amd64 xen-tools

    # Ganeti
    apt-get -y install drbd8-utils ganeti-instance-debootstrap ganeti2 ganeti-htools \
      fai-client ghc libghc-json-dev libghc-network-dev libghc-parallel-dev libghc-curl-dev \
      linux-image-extra-virtual

    depmod -a
    hi "Dependencies installed!"
}

function system_configuration {
    cd $HOME
    # System and network configuration
    ! grep -s -q dom0_mem=512 /etc/default/grub.d/xen.cfg && \
      sed -i '1s/^/GRUB_CMDLINE_XEN_DEFAULT="dom0_mem=512M,max:512M dom0_max_vcpus=1,dom0_vcpus_pin"/' /etc/default/grub.d/xen.cfg && \
        update-grub2
    echo "service ssh restart" > /etc/init.d/ssh # Bug: https://bugs.launchpad.net/ubuntu/+source/ganeti/+bug/1308571
    echo "${HOSTNAME}.test" > /etc/hostname
    sed -i -e '/#autoballoon/s/^#//' -e '/^autoballoon/s/auto/off/2' /etc/xen/xl.conf
    ln -f -s /boot/vmlinuz-$(uname -r) /boot/vmlinuz-3-xenU
    ln -f -s /boot/initrd.img-$(uname -r) /boot/initrd-3-xenU

    if [ -e $HOME/interfaces* ]; then
        install -o root -g root -m 644 $HOME/interfaces* /etc/network/interfaces.d/xen.cfg
    fi
    if [ -e $HOME/hosts ]; then
        install -o root -g root -m 644 $HOME/hosts /etc/hosts
    fi
    if [ -e $HOME/modules ]; then
        install -o root -g root -m 644 $HOME/modules /etc/modules
    fi
    if [ -e $HOME/xend-config.sxp ]; then
        install -o root -g root -m 644 $HOME/xend-config.sxp /etc/xen/xend-config.sxp
    fi
    if [ -e $HOME/lvm.conf ]; then
        install -o root -g root -m 644 $HOME/lvm.conf /etc/xen/lvm.conf
    fi
    if [ -e $HOME/authorized_keys ]; then
        install -o root -g root -m 600 $HOME/authorized_keys /root/.ssh/authorized_keys
    fi
    if [ -e $HOME/id_rsa.pub ]; then
        install -o root -g root -m 600 $HOME/id_rsa.pub /root/.ssh/authorized_keys
    fi
    if [ -e $HOME/id_rsa ]; then
        install -o root -g root -m 600 $HOME/id_rsa /root/.ssh/id_rsa
        install -o root -g root -m 600 $HOME/id_rsa.pub /root/.ssh/id_rsa.pub
    fi
    lvm_configuration
    hi "Everything ran! Time for a reboot"
}

function lvm_configuration {
  if [ -b /dev/sdb ]; then
    pvcreate /dev/sdb
    vgcreate ganeti /dev/sdb
  fi
}

if ! which xen 2>&1 > /dev/null; then
 	install_dependencies
        system_configuration
fi

lsmod | grep -q drbd && echo "Initializing cluster!" && \
  gnt-cluster init --enabled-hypervisors=xen-pvm --hypervisor-parameters xen-pvm:xen_cmd=xl --vg-name ganeti --nic-parameters link=xenbr0 \
   --master-netdev eth2 --secondary-ip 192.168.1.10 --backend-parameters vcpus=1,memory=128M xen-cluster.test && \
  echo  "Add a node to the cluster: gnt-node add -v -d -s 192.168.1.20 xen-node2.test"
