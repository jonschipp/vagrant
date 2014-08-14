#!/usr/bin/env bash
# Tested on CentOS
# Cannot install Netsniff-NG because lack of TPACKET_V3 support in kernel, a problem with EL systems)
# Installs: ifpps trafgen bpfc flowtop mausezahn astraceroute
# Optional: To build curvetun uncomment NaCL lines in install_nestniff-ng function and add to make line

DESIRED_TOOLKIT_VERSION="$1" # e.g. ./install_netsniff-ng.sh "0.5.9-rc2+"
DIR=/root
HOST=$(hostname -s)
IRCSAY=/usr/local/bin/ircsay
COWSAY=$(which cowsay 2>/dev/null)
LOGFILE=netsniff-ng-install.log

exec > >(tee -a "$LOGFILE") 2>&1
echo -e "\n --> Logging stdout & stderr to $LOGFILE"

function die {
    if [ -f ${COWSAY:-none} ]; then
	$COWSAY -d "$*"
    else
    	echo "$*"
    fi
    if [ -f $IRCSAY ]; then
    	( set +e; $IRCSAY "#company-channel" "$*" 2>/dev/null || true )
    fi
    # echo "$*" | mail -s "Netsniff-NG install information on $HOST" user@company.com
    exit 1
}

function hi {
    if [ -f ${COWSAY:-none} ]; then
	$COWSAY "$*"
    else
    	echo "$*"
    fi
    if [ -f $IRCSAY ]; then
    	( set +e; $IRCSAY "#company-channel" "$*" 2>/dev/null || true )
    fi
    # echo "$*" | mail -s "Netsniff-NG install information on $HOST" user@company.com
}

function cleanup() {
local ORDER=$1
echo "$ORDER Cleaning up any messes!"
cd $DIR
if [ -f libcli-1.8.6-2.el6.rf.x86_64.rpm ]; then
        rm -fr libcli-1.8.6-2.el6.rf.x86_64.rpm
fi

if [ -f libcli-devel-1.8.6-2.el6.rf.x86_64.rpm ]; then
        rm -fr libcli-devel-1.8.6-2.el6.rf.x86_64.rpm
fi
if [ -f epel-release-6-8.noarch.rpm ]; then
        rm -fr epel-release-6-8.noarch.rpm
fi
rm -rf nacl*
rm -rf libnl-3.2.25*
if [ -d netsniff-ng ]; then
        rm -fr netsniff-ng
fi
}

function check_version() {
local ORDER=$1
echo "$ORDER Checking version!"
if [ -f /usr/local/sbin/mausezahn ]; then
        INSTALLED_VERSION=$(/usr/local/sbin/mausezahn -h | awk '/mausezahn/ && NR == 2 { gsub(",",""); print $2 }')

        if [[ "$INSTALLED_VERSION" == "$DESIRED_TOOLKIT_VERSION" ]]; then
                echo "Current version $DESIRED_TOOLKIT_VERSION is already installed."
		rm -f $0
                exit 0
        fi
fi
}

function install_dependencies()
{
local ORDER=$1
echo -e "$ORDER Checking for dependencies!\n"
if [ ! -f /etc/yum.repos.d/epel.repo ]; then
	rpm -Uvh http://download.fedoraproject.org/pub/epel/6/i386/epel-release-6-8.noarch.rpm && hi "Installed EPEL repo!" || die "Failed to install EPEL"
fi

yum install -y wget git ccache flex bison GeoIP-devel \
	 libnetfilter_conntrack-devel ncurses-devel \
	 userspace-rcu-devel libpcap-devel zlib-devel \
	 libnet-devel gnuplot cpp
echo
if [ ! -f /usr/lib64/libcli.so.1.8.6 ]; then
	rpm -ivh http://pkgs.repoforge.org/libcli/libcli-1.8.6-2.el6.rf.x86_64.rpm && hi "Installed libcli!" || die "Failed to install libcli"
fi
if [ ! -f /usr/include/libcli.h ]; then
	rpm -ivh http://pkgs.repoforge.org/libcli/libcli-devel-1.8.6-2.el6.rf.x86_64.rpm && hi "Installed libcli-devel!" || die "Failed to install libcli-devel"
fi
if [ ! -d /usr/local/lib/libnl ]; then
	wget http://www.infradead.org/~tgr/libnl/files/libnl-3.2.25.tar.gz
	tar zxf libnl-3.2.25.tar.gz
	cd libnl-3.2.25
	./configure && make && make install && hi "Installed libnl-3.2.25" || die "Failed to install libnl-3.2.25"
fi
}

function install_netsniff-ng() {
local ORDER=$1
echo -e "$ORDER Installing from source!\n"
cd $DIR
if git clone https://github.com/netsniff-ng/netsniff-ng.git
then
        cd netsniff-ng
	./configure 2>&1 > /dev/null
	# Uncomment next 4 lines to build library for curvetun, then add "curvetun" and curvetun_install to make line.
	# make nacl
	# source <(grep '=' curvetun/nacl_build.sh | sed 's/abiname/curvetun\/abiname/')
	# export NACL_LIB_DIR=/root/nacl/$nacl_version/build/$shorthostname/lib/$arch
	# export NACL_INC_DIR=/root/nacl/$nacl_version/build/$shorthostname/include/$arch
	export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig
  ./configure && make ifpps trafgen bpfc flowtop mausezahn astraceroute && make ifpps_install trafgen_install bpfc_install flowtop_install mausezahn_install astraceroute_install

	if [ $? -eq 0 ]; then
		hi "Netsniff-NG successfully installed!"
	else
		die "Netsniff-NG tools failed to install"
	fi
else
	die "Netsniff-NG download failed"
fi
}

function configuration() {
local ORDER=$1
echo -e "$ORDER Configuring the system for best use!\n"

if [ ! -f /etc/ld.so.conf.d/libnl.conf ]; then
	echo "/usr/local/lib" > /etc/ld.so.conf.d/libnl.conf
	ldconfig
fi

if [ -d /etc/sysctl.d ] && [ ! -f /etc/sysctl.d/10-bpf.conf ]; then
cat > /etc/sysctl.d/10-bpf.conf <<EOF
# Enable BPF JIT Compiler (approx. 50ns speed up)
net.core.bpf_jit_enable = 2
EOF
fi
}

# Remove if someone manually left files
cleanup "1.)"
# Check version to update when new is available (specified as argument)
check_version "2.)"
install_dependencies "3.)"
install_netsniff-ng "4.)"
configuration "5.)"
cleanup "6.)"
exit 0
