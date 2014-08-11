#!/bin/bash
VAGRANT=/home/vagrant
if [ -d $VAGRANT ]; then
	HOME=/home/vagrant
else
	HOME=/root
fi
COWSAY=/usr/games/cowsay
IRCSAY=/usr/local/bin/ircsay
IRC_CHAN="#replace_me"
HOST=$(hostname -s)
LOGFILE=/root/bro-sandbox_install.log
DST=/usr/local/bin
EMAIL=jonschipp@gmail.com

exec > >(tee -a "$LOGFILE") 2>&1
echo -e "\n --> Logging stdout & stderr to $LOGFILE"

if [ $UID -ne 0 ]; then
	echo "Script must be run as root user, exiting..."a
	exit 1
fi

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

function logo {
cat <<"EOF"
===========================================

		Bro
	    -----------
	  /             \
	 |  (   (0)   )  |
	 |            // |
	  \     <====// /
	    -----------

	Web: http://bro.org

===========================================

EOF
}

no_vagrant_setup() {
local COUNT=0
local SUCCESS=0
FILES="
https://raw.githubusercontent.com/jonschipp/vagrant/master/bro-sandbox/etc.default.docker
https://raw.githubusercontent.com/jonschipp/vagrant/master/bro-sandbox/sandbox.cron
https://raw.githubusercontent.com/jonschipp/vagrant/master/bro-sandbox/scripts/remove_old_containers
https://raw.githubusercontent.com/jonschipp/vagrant/master/bro-sandbox/scripts/remove_old_users
https://raw.githubusercontent.com/jonschipp/vagrant/master/bro-sandbox/scripts/disk_limit
https://raw.githubusercontent.com/jonschipp/vagrant/master/bro-sandbox/scripts/sandbox_login
https://raw.githubusercontent.com/jonschipp/vagrant/master/bro-sandbox/scripts/sandbox_shell
"

echo -e "Downloading required configuration files!\n"

for url in $FILES
do
	COUNT=$((COUNT+1))
	wget $url 2>/dev/null
	if [ $? -ne 0 ]; then
		echo "$COUNT - Download for $url failed!"
	else
		echo "$COUNT - Success! for $url"
		SUCCESS=$((SUCCESS+1))
	fi
done
echo
}

function install_docker() {
local ORDER=$1
echo -e "$ORDER Installing Docker!\n"

# Check that HTTPS transport is available to APT
if [ ! -e /usr/lib/apt/methods/https ]; then
	apt-get update
	apt-get install -y apt-transport-https
fi

# Add the repository to your APT sources
# Then import the repository key
if [ ! -e /etc/apt/sources.list.d/docker.list ]
then
	echo deb https://get.docker.io/ubuntu docker main > /etc/apt/sources.list.d/docker.list
	apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 36A1D7869245C8950F966E92D8576A8BA88D21E9
fi

# Install docker
if ! command -v docker >/dev/null 2>&1
then
	apt-get update ; apt-get install -y lxc-docker
fi
}

function user_configuration() {
local ORDER=$1
local SSH_CONFIG=/etc/ssh/sshd_config 
echo -e "$ORDER Configuring the demo user account!\n"

if [ ! -e /etc/sudoers.d/sandbox ]; then
cat > /etc/sudoers.d/sandbox <<EOF
Cmnd_Alias SANDBOX = /usr/bin/docker
demo ALL=(root) NOPASSWD: SANDBOX
EOF
chmod 0440 /etc/sudoers.d/sandbox && chown root:root /etc/sudoers.d/sandbox
fi

if ! grep -q sandbox /etc/shells
then
	sh -c 'echo /usr/local/bin/sandbox_shell >> /etc/shells'
fi

if ! getent passwd demo 1>/dev/null
then
	adduser --disabled-login --gecos "" --shell $DST/sandbox_shell demo
	sed -i '/demo/s/:!:/:$6$CivABH1p$GU\/U7opFS0T31c.6xBRH98rc6c6yg9jiC5adKjWo1XJHT3r.25ySF5E5ajwgwZlSk6OouLfIAjwIbtluf40ft\/:/' /etc/shadow
fi

if ! grep -q "Match User demo" $SSH_CONFIG
then
cat <<"EOF" >> $SSH_CONFIG
Match User demo
	PasswordAuthentication yes
EOF

	restart ssh
	echo
fi
}

function system_configuration() {
local ORDER=$1
local LIMITS=/etc/security/limits.d
echo -e "$ORDER Configuring the system for use!\n"

if [ -e $HOME/sandbox_shell ]; then
	mv $HOME/sandbox_shell $DST/sandbox_shell
	chmod 755 $DST/sandbox_shell && chown root:root $DST/sandbox_shell
fi

if [ -e $HOME/sandbox_login ]; then
	mv $HOME/sandbox_login $DST/sandbox_login
	chmod 755 $DST/sandbox_login && chown root:root $DST/sandbox_login
fi

if [ -e $HOME/sandbox.cron ]; then
	mv $HOME/sandbox.cron /etc/cron.d/sandbox
	chmod 644 /etc/cron.d/sandbox && chown root:root /etc/cron.d/sandbox
fi

if [ ! -e $LIMITS/fsize.conf ]; then
	echo "*                hard    fsize           1000000" > $LIMITS/fsize.conf
fi

if [ ! -e $LIMITS/nproc.conf ]; then
	echo "*                hard    nproc           10000" > $LIMITS/nproc.conf
fi
}

function container_scripts(){
local ORDER=$1
echo -e "$ORDER Installing container maintainence scripts!\n"

for FILE in disk_limit remove_old_containers remove_old_users
do
	if [ -e $HOME/$FILE ]; then
		mv $HOME/$FILE $DST/sandbox_${FILE}
		chmod 750 $DST/sandbox_${FILE} && chown root:root $DST/sandbox_${FILE}
	fi
done
}

function docker_configuration() {
local ORDER=$1
local DEFAULT=/etc/default/docker
local UPSTART=/etc/init/docker.conf

echo -e "$ORDER Installing the Bro Sandbox Docker image!\n"


if ! grep -q "limit fsize" $UPSTART
then
	sed -i '/limit nproc/a limit fsize 500000000 500000000' $UPSTART
fi

if ! grep -q "limit nproc 524288 524288" $UPSTART
then
	sed -i '/limit nproc/s/[0-9]\{1,8\}/524288/g' $UPSTART
fi

if ! grep -q devicemapper $DEFAULT
then
	mv $HOME/etc.default.docker $DEFAULT
	chmod 644 $DEFAULT && chown root:root $DEFAULT
	rm -rf /var/lib/docker/
	mkdir -p /var/lib/docker/devicemapper/devicemapper
	restart docker
	sleep 10
fi


if ! docker images | grep -q jonschipp/latest-bro-sandbox
then
	docker pull jonschipp/latest-bro-sandbox
	#docker build -t sandbox - < Dockerfile
	#docker commit $(docker ps -a -q | head -n 1) sandbox
fi

if [ ! -d /exercises ]
then
	mkdir /exercises
fi
}

logo

if [ ! -d $VAGRANT ]; then
	no_vagrant_setup
fi

install_docker "1.)"
user_configuration "2.)"
system_configuration "3.)"
container_scripts "4.)"
docker_configuration "5.)"

if [ -d $VAGRANT ]; then
        echo "Try it out: ssh -p 2222 demo@127.0.0.1 -o UserKnownHostsFile=/dev/null"
else
        echo "Try it out: ssh demo@<ip> -o UserKnownHostsFile=/dev/null"
fi
