#!/bin/bash
# Author: Jon Schipp <jonschipp@gmail.com>
# Written for Ubuntu Saucy and Trusty, should be adaptable to other distros.

## Variables
HOME=/root
cd $HOME

# Installation notification
COWSAY=/usr/games/cowsay
IRCSAY=/usr/local/bin/ircsay
IRC_CHAN="#replace_me"
HOST=$(hostname -s)
LOGFILE=/root/islet_install.log
EMAIL=user@company.com

function die {
    if [ -f ${COWSAY:-none} ]; then
        $COWSAY -d "$*"
    else
        echo "$*"
    fi
    if [ -f $IRCSAY ]; then
        ( set +e; $IRCSAY "$IRC_CHAN" "$*" 2>/dev/null || true )
    fi
    echo "$*" | mail -s "[vagrant] Bro Sandbox install information on $HOST" $EMAIL
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
    echo "$*" | mail -s "[vagrant] Bro Sandbox install information on $HOST" $EMAIL
}

install_dependencies(){
apt-get update -qq
apt-get install -yq cowsay git make sqlite pv
}

monitoring(){
# Yes, I want to get your stats to see how ISLET performs
# and you can view them too: http://graphite.jonschipp.com:8080/
apt-get update -qq
apt-get install -yq collectd
sed -i '/LoadPlugin network/s/^#//' /etc/collectd/collectd.conf
cat <<EOF > /etc/collectd/collectd.conf.d/islet.conf
<Plugin "network">
        Server "graphite.jonschipp.com" "25826"
</Plugin>

LoadPlugin syslog
LoadPlugin battery
LoadPlugin cgroups
LoadPlugin conntrack
LoadPlugin contextswitch
LoadPlugin cpu
LoadPlugin cpufreq
LoadPlugin df
LoadPlugin disk
LoadPlugin entropy
LoadPlugin ethstat
LoadPlugin exec
LoadPlugin filecount
LoadPlugin interface
LoadPlugin iptables
LoadPlugin irq
LoadPlugin load
LoadPlugin lvm
LoadPlugin memory
LoadPlugin netlink
LoadPlugin processes
LoadPlugin protocols
LoadPlugin swap
LoadPlugin tcpconns
LoadPlugin unixsock
LoadPlugin uptime
LoadPlugin users
LoadPlugin vmem
EOF
service collectd restart
}

install_islet(){
if ! [ -d islet ]
then
	git clone http://github.com/jonschipp/islet || die "Clone of islet repo failed"
	cd islet
	make install-docker && make docker-config && ./configure && make logo &&
	make install && make user-config && make security-config && make iptables-config
	make install-brolive-config
	#make install-sample-distros
	make install-sample-nsm
fi
}

install_dependencies "1.)"
install_islet "2.)"
# Comment out if you don't want to send me your system's data.
monitoring "3.)"

echo -e "\nTry it out: ssh -p 2222 $USER@127.0.0.1 -o UserKnownHostsFile=/dev/null"
