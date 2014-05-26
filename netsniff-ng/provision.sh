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

function logo {
cat <<"EOF"
=================================================================

netsniff-ng is a free, performant       /(      )\
Linux network analyzer and            .' {______} '.
networking toolkit. If you will,       \ ^,    ,^ /
the Swiss army knife for network        |'O\  /O'|   _.<0101011>--
packets.                                > `'  '` <  /
                                        ) ,.==., (  |
Web: http://netsniff-ng.org          .-(|/--~~--\|)-'
                                    (      ___
                                     \__.=|___E

=================================================================
EOF
}

function install_dependencies {
    # Install dependencies
    apt-get update
    apt-get -y install cowsay git language-pack-en libreadline-dev

    # Netsniff-NG
    apt-get -y install language-pack-en git ccache flex bison libnl-3-dev \
      libnl-genl-3-dev libgeoip-dev libnetfilter-conntrack-dev \
      libncurses5-dev liburcu-dev libnacl-dev libpcap-dev \
      zlib1g-dev libcli-dev libnet1-dev

    # Perf tools
    apt-get -y install libaudit-dev libelf-dev libgtk2.0-dev libunwind8-dev \
    	libnuma-dev libslang2-dev libdw-dev binutils-dev asciidoc xmlto

    hi "Dependencies installed!"
}


function install_netsniff-ng {
   cd $HOME
   # Compile latest Netsniff-NG
   if [ ! -d $HOME/netsniff-ng ]
   then
   	git clone http://github.com/netsniff-ng/netsniff-ng
   	cd netsniff-ng
   	./configure
   	mkdir -p /usr/local/share/man/man8/
   	make && make install && hi "Netsniff-NG Installed!" || die "Failed to install netsniff-ng!"
   fi
}

function install_helper_tools {
   cd $HOME
   # Download other useful testing tools
   if [ ! -d $HOME/gencfg ]
   then
   	git clone http://github.com/jonschipp/gencfg
   fi
   if [ ! -d $HOME/network-testing ]
   then
   	git clone https://github.com/netoptimizer/network-testing
   fi
   hi "Helper tools installed!"
}

function install_linux_kernel {
    cd $HOME

    if [ ! -d $KERNEL ]
    then
        # Download, compile, and install latest stable kernel
        wget --progress=dot:mega -O - $LATEST_STABLE_KERNEL_URL | tar -xJ
        if [ $? -ne 0 ]; then die "Failed to download and decompress the linux kernel"; fi
        cd $KERNEL
        #mv config $KERNEL/.config
        make config
        make -j 4 || die "Failed to build kernel!"
        make -j 4 modules || die "Failed to build kernel modules!"
        make modules_install || die "Failed to install kernel modules!"
        make install || die "Failed to install kernel!"
        $COWSAY -f tux "Linux kernel $KERNEL installed!"
    fi
}

function install_bpf_tools {
    # Compile and install bpf debugging programs
    cd $HOME/$KERNEL/tools/net
    if ! which bpf_asm 2>&1 > /dev/null; then
        make bpf_asm && BPF=1
    fi
    if ! which bpf_asm 2>&1 > /dev/null; then
        make bpf_dbg && BPF=1
    fi
    if ! which bpf_jit_disasm 2>&1 > /dev/null; then
        make bpf_jit_disasm && BPF=1
    fi
    test $BPF -eq 1 && make install && hi "BPF Helper Tools Installed!"
}

function install_perf_tools {
    # Compile and install perf tools
    if [ ! -e /usr/sbin/perf ]; then
        cd $HOME/$KERNEL/tools/perf
        make && make install && hi "Perf tools installed!" || die "Perf tools failed to install!"
        ln -s $HOME/bin/perf /usr/sbin/perf
    fi
}

function system_configuration {
    cd $HOME
    # System and network configuration
    if [ -e $HOME/nlmon.cfg ]; then
    	mv $HOME/nlmon.cfg /etc/network/interfaces.d/nlmon.cfg
    fi
if [ ! -e /etc/sysctl.d/10-bpf.conf ]; then
cat > /etc/sysctl.d/10-bpf.conf <<EOF
# Enable BPF JIT Compiler (approx. 50ns speed up)
net.core.bpf_jit_enable = 2
EOF
fi
    hi "Everything ran! Time for a reboot"
}

logo

if ! which netsniff-ng 2>&1 > /dev/null; then
	install_dependencies
	install_netsniff-ng
fi

install_helper_tools

if [ "$CURRENT" != "$KERNEL" ] && [ $UPDATE -eq 1 ]; then
	install_linux_kernel
fi

install_bpf_tools
install_perf_tools
system_configuration
reboot
