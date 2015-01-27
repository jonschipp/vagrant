#!/bin/bash
# Author: Jon Schipp <jonschipp@gmail.com>
# Written for Ubuntu Saucy and Trusty, should be adaptable to other distros.

## Variables
PROVIDER="$1"
HOME=/root
VAGRANT=/home/vagrant
PREFIX=/opt/cuckoo
CONFIG=$PREFIX/conf
PACKAGES="cowsay unzip python python-sqlalchemy python-bson git bison flex python-dpkt python-jinja2 python-yara python-magic python-pymongo python-gridfs python-libvirt python-bottle python-pefile python-chardet volatility tcpdump libcap2-bin mongodb python-django python-dev libfuzzy-dev python-pip ssdeep"
[ -e /etc/redhat-release ] && OS=el
[ -e /etc/debian_version ] && OS=debian

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
  [ "$OS" = "debian" ] && count=$(dpkg -l | egrep "  $pkg_list" | wc -l)
  [ "$OS" = "el" ]     && count=$(yum list installed | egrep "$pkg_list" | wc -l)

  if [ $count -ge $package_count ]
  then
    return 0
  else
    echo "Installing packages for function!"
    [ "$OS" = "debian" ] && yum install -qy $packages
    [ "$OS" = "el" ]     && apt-get install -qy $packages
  fi
}

install_dependencies(){
  echo "$1 $FUNCNAME"
  [ "$OS" = "debian" ] && apt-get update -qq
  [ "$OS" = "el" ]     && yum makecache -q
  # Required
  package_check $PACKAGES
    # maec
  pip install pydeep distorm3
  install_yara
  install_distorm
  [ $PROVIDER ] || die "Argument not specified, pass either virtualbox or kvm as argument"
  [ "$PROVIDER" == "virtualbox" ] && install_virtualbox
  [ "$PROVIDER" == "kvm" ] && install_kvm
}

install_virtualbox(){
  [ -e /etc/apt/sources.list.d/virtualbox.list ] || echo "deb http://download.virtualbox.org/virtualbox/debian $(lsb_release -cs) contrib non-free" > /etc/apt/sources.list.d/virtualbox.list &&
    wget -q http://download.virtualbox.org/virtualbox/debian/oracle_vbox.asc -O - | apt-key add - && apt-get update
  package_check virtualbox-4.3 dkms
  [ -d $HOME/.config ] || mkdir -p -m 700 $HOME/.config/VirtualBox
  [ -e $VAGRANT/VirtualBox.xml ] && install -o root -g root -m 600 $VAGRANT/VirtualBox.xml $HOME/.config/VirtualBox
  mkdir -p /root/VirtualBox\ VMs/Cuckoo/
}

install_kvm(){
  [ $VT -eq 1 ] || die "KVM is not supported by the hardware, use virtualbox instead"
  package_check qemu-kvm libvirt-bin ubuntu-vm-builder bridge-utils
}

install_mysql(){
  echo "$1 $FUNCNAME"
  debconf-set-selections <<< 'mysql-server mysql-server/root_password password password'
  debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password password'
  package_check mysql-server python-mysqldb
  mysql --user=root --password=password -e "CREATE DATABASE cuckoo;" || die "Failed to create MySQL cuckoo database"
  mysql --user=root --password=password -e "CREATE USER 'cuckoo'@'localhost' IDENTIFIED BY 'password';"
  mysql --user=root --password=password -e "GRANT ALL PRIVILEGES ON cuckoo.* TO 'cuckoo'@'localhost' WITH GRANT OPTION;"
  mysql --user=root --password=password -e "CREATE USER 'cuckoo'@'%' IDENTIFIED BY 'password';"
  mysql --user=root --password=password -e "GRANT ALL PRIVILEGES ON cuckoo.* TO 'cuckoo'@'%' WITH GRANT OPTION;"
}

install_yara() {
  echo "$1 $FUNCNAME"
  package_check libpcre3 libpcre3-dev libtool automake autoconf autotools-dev libjansson-dev libmagic-dev
  if ! [ -d yara ]
  then
    git clone https://github.com/plusvic/yara
    cd yara
    ./bootstrap.sh && ./configure --enable-cuckoo --enable-magic && make && make install || die "yara failed to install"
    pip install yara-python || die "yara-python failed to install"
  fi
}

install_distorm() {
  echo "$1 $FUNCNAME"
  if ! [ -d distorm3 ]
  then
    wget http://distorm.googlecode.com/files/distorm-package3.1.zip || die "Failed to download distorm3"
    unzip distorm-package3.1.zip
    cd distorm3
    python setup.py build
    python setup.py install
  fi
}

configure_dependencies(){
  echo "$1 $FUNCNAME"
  if ! getcap /usr/sbin/tcpdump | grep -q cap_net_admin,cap_net_raw
  then
    setcap cap_net_raw,cap_net_admin=eip /usr/sbin/tcpdump
  fi
}

configure_users(){
  echo "$1 $FUNCNAME"
  getent passwd cuckoo 1>/dev/null 	  || adduser --disabled-password  --gecos "" --shell /bin/bash cuckoo
  getent group vboxusers | grep -q cuckoo || usermod -a -G vboxusers cuckoo 2>/dev/null
  getent group libvirtd  | grep -q cuckoo || usermod -a -G libvirtd cuckoo 2>/dev/null
  getent group kvm       | grep -q cuckoo || usermod -a -G kvm cuckoo 2>/dev/null
}

install_cuckoo(){
  echo "$1 $FUNCNAME"
  if ! [ -d $PREFIX ]
  then
    git clone git://github.com/cuckoobox/cuckoo.git $PREFIX || die "Clone of cuckoo repo failed"
  fi
}

configure_cuckoo(){
  echo "$1 $FUNCNAME"
  [ -e $VAGRANT/cuckoo.conf ]       && install -o root -g root -m 644 $VAGRANT/cuckoo.conf $CONFIG/cuckoo.conf
  [ -e $VAGRANT/memory.conf ]       && install -o root -g root -m 644 $VAGRANT/memory.conf $CONFIG/memory.conf
  [ -e $VAGRANT/auxiliary.conf ]    && install -o root -g root -m 644 $VAGRANT/auxiliary.conf $CONFIG/auxiliary.conf
  [ -e $VAGRANT/reporting.conf ]    && install -o root -g root -m 644 $VAGRANT/reporting.conf $CONFIG/reporting.conf
  [ -e $VAGRANT/virtualbox.conf ]   && install -o root -g root -m 644 $VAGRANT/virtualbox.conf $CONFIG/virtualbox.conf
  [ -e $VAGRANT/kvm.conf ]          && install -o root -g root -m 644 $VAGRANT/kvm.conf $CONFIG/kvm.conf
  [ -e $VAGRANT/local_settings.py ] && install -o root -g root -m 644 $VAGRANT/local_settings.py $PREFIX/web/web/local_settings.py
  [ -e $VAGRANT/upstart.conf ]      && install -o root -g root -m 644 $VAGRANT/upstart.conf /etc/init/cuckoo.conf
  [ -e $VAGRANT/cuckoo-api.conf ]   && install -o root -g root -m 644 $VAGRANT/cuckoo-api.conf /etc/init/cuckoo-api.conf
  [ -e $VAGRANT/cuckoo-web.conf ]   && install -o root -g root -m 644 $VAGRANT/cuckoo-web.conf /etc/init/cuckoo-web.conf
  [ $VT ] && sed -i '/^machinery/s/virtualbox/kvm/' $PREFIX/conf/cuckoo.conf
  install_mysql
  start cuckoo && start cuckoo-api && start cuckoo-web
}

network_configuration(){
  echo "$1 $FUNCNAME"
  sed -i 's/without-password/yes/' /etc/ssh/sshd_config && restart ssh
cat <<EOF > /etc/network/if-pre-up.d/iptables-rules
# Flushing all rules
iptables -F
iptables -X
# Adding guest access to network
iptables -A FORWARD -o eth0 -i vboxnet0 -s 192.168.122.0/24 -m conntrack --ctstate NEW -j ACCEPT
iptables -A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -A POSTROUTING -t nat -j MASQUERADE
EOF
  chmod 750 /etc/network/if-pre-up.d/iptables-rules
  /etc/network/if-pre-up.d/iptables-rules
  echo "net.ipv4.ip_forward=1" > /etc/sysctl.d/cuckoo.conf
  sysctl -p
}

# Test for hardware virtualization
egrep -q '(vmx|svm)' /proc/cpuinfo && VT=1

hi "Chosen provider is $PROVIDER"
install_dependencies "1.)"
configure_dependencies "2.)"
configure_users "3.)"
install_cuckoo "4.)"
configure_cuckoo "5.)"
network_configuration "6.)"

pgrep -f "/usr/bin/python /opt/cuckoo/cuckoo.py" 1>/dev/null && hi "Installation successful! $(status cuckoo)..."
