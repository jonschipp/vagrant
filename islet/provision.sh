#!/bin/bash
# Author: Jon Schipp <jonschipp@gmail.com>
# Written for Ubuntu Saucy and Trusty, should be adaptable to other distros.

## Variables
VAGRANT=/home/vagrant
if [ -d $VAGRANT ]; then
	HOME=/home/vagrant
else
	HOME=/root
fi

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
apt-get install -yq cowsay git make
}

install_islet(){
if ! [ -d islet ]
then
	git clone http://github.com/jonschipp/islet
	if [ -d islet ]
	then
		cd islet
		make install-docker && ./configure && make logo &&
		make install && make user-config && make security-config
		make install-brolive-config
		#make install-sample-distros
		make install-sample-nsm
	else
		die "Clone of islet repo failed"
	fi
fi
}

install_dependencies "1.)"
install_islet "2.)"

echo
echo "Try it out: ssh -p 2222 $USER@127.0.0.1 -o UserKnownHostsFile=/dev/null"
