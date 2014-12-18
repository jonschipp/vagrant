#!/bin/bash
# We start here
HOME=/home/root
ARG=${1:-0}
BPF=0
COWSAY=/usr/games/cowsay
cd $HOME

# /usr/lib/ganeti/tools/burnin -v -d -o debootstrap+default --disk-size=1024m --mem-size=128m -p instance1
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
       sed -i '1s/^/GRUB_CMDLINE_XEN_DEFAULT="dom0_mem=512M,max:512M dom0_max_vcpus=1 dom0_vcpus_pin=1"/' /etc/default/grub.d/xen.cfg && \
        update-grub2
    echo "service ssh restart" > /etc/init.d/ssh # Bug: https://bugs.launchpad.net/ubuntu/+source/ganeti/+bug/1308571
    echo "${HOSTNAME}.test" > /etc/hostname
    sed -i -e '/#autoballoon/s/^#//' -e '/^autoballoon/s/auto/off/2' /etc/xen/xl.conf
    sed -i '/dowait 120/d'  /etc/init/cloud-init-nonet.conf
    sed -i 's/dowait/10/2/' /etc/init/cloud-init-nonet.conf
    sed -i '/sleep 40/d' /etc/init/failsafe.conf
    sed -i '/sleep 59/d' /etc/init/failsafe.conf
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
    ssh_configuration
    ufw disable
    lvm_configuration
    hi "Everything ran! Time for a reboot"
}

function ssh_configuration {
SSH=$HOME/.ssh
mkdir -m 700 -p $SSH
cat <<EOF > $SSH/known_hosts
|1|wCuhVl1I0CngsoebC3ocaiiMWB4=|zQU6X90gpDUdXzrE7s6kpOQQNL0= ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBNqKwGOU6Vxuhb013C8Wvmaxl6uJ6+YobkKgWDp5l/k6G5fg7BrWibnc3CiKTN+wH0RW6WYk2AeUvXFWASDxpmM=
|1|sUP7jPO2XR+Wsu3jzspJhufLHNE=|r/FpqGK+yZC+MQdaps9oIUzV4xs= ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBNqKwGOU6Vxuhb013C8Wvmaxl6uJ6+YobkKgWDp5l/k6G5fg7BrWibnc3CiKTN+wH0RW6WYk2AeUvXFWASDxpmM=
EOF
cat <<EOF > $SSH/id_dsa.pub
ssh-dss AAAAB3NzaC1kc3MAAACBAIHNYzf38A+PHIpSYd7B78XAUnnqTWtxGON4LRCcGOk4aDfY5FF7B5v5ywLBb6HBQZ0oVur/cW87r0Cj9yP56haZtq09JIBAywWpIKnWkE5+gzs62IDq7mXxvmx3sNArpvbGfzCV9yY3hdeEHqYtwI6fOygb1hRR52XfoIso7EADAAAAFQCSxXJGVzoHeuGTR49pYRKyaNjVjwAAAIBJSo/c9iBCIKvrKUHbnA2EohG4B1K6PFUX6OLCeqVlzDZHwaYXHDQnrSSOmqK8RyttsGhWEC16kp8bc/ldm/xQuGmaXqqtk9mS9MGDAeJgXx3lD5XkIYbrypSGSuVG5UtC6nFKxbWklEF0rSvm+yDnyaoKlYkA6+52ngx85bT10wAAAIBh7YhYuy6YHilCcbkAa0UvVu6Lds+nqnh+jdc4A+Phijt3i8q6/yDJj0WhM9TVgo7TKzbe7/SpzU98gdY2bOxZd1xNjFyquVEP92+LAm+s/OCbU7n3g43EWKfq5M6fpIPtXzEOFMRuOncg7EEGywDz3cyaCD+mtuI6hF3beG0ntA== root@xen-node1.test
EOF
cat <<EOF > $SSH/authorized_keys
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
        system_configuration
fi

cat <<EOF
Run these commands on node1 to create the cluster:
$ vagrant ssh node1
$ gnt-cluster init --enabled-hypervisors=xen-pvm --hypervisor-parameters xen-pvm:xen_cmd=xl --vg-name ganeti --nic-parameters link=xenbr0 \
--master-netdev eth2 --secondary-ip 192.168.1.10 --backend-parameters vcpus=1,minmem=64,maxmem=256M,always_failover=true xen-cluster.test
$ gnt-node add -v -d -s 192.168.1.20 xen-node2.test
EOF

reboot
