#!/bin/bash
# Author: Jon Schipp <jonschipp@gmail.com>
# Written for Ubuntu Saucy and Trusty, should be adaptable to other distros.

## Variables
export DEBIAN_FRONTEND=noninteractive
HOME=/root
cd $HOME

# Installation notification
COWSAY=/usr/games/cowsay
IRCSAY=/usr/local/bin/ircsay
IRC_CHAN="#replace_me"
HOST=$(hostname -s)
LOGFILE=/root/collectd_install.log
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
    echo "$*" | mail -s "[vagrant] ISLET install information on $HOST" $EMAIL
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
    echo "$*" | mail -s "[vagrant] ISLET install information on $HOST" $EMAIL
}

install_dependencies(){
apt-get update -qq
apt-get install -yq cowsay git ca-certificates apparmor expect
}

install_collectd(){
COLLECTD=/etc/collectd/collectd.conf
COLLECTD_LUG=/etc/collectd/collectd.conf.d/lug.conf
apt-get update -qq
apt-get install -yq collectd
grep -q "^LoadPlugin network" $COLLECTD || sed -i '/LoadPlugin network/s/^#//' $COLLECTD
grep -q "^LoadPlugin write_graphite" $COLLECTD || sed -i '/LoadPlugin write_graphite/s/^#//' $COLLECTD
if ! [ -f $COLLECTD_LUG ]; then
cat <<EOF > $COLLECTD_LUG
<Plugin "network">
	Listen "0.0.0.0" "25826"
</Plugin>

<Plugin write_graphite>
	<Node "collectd">
		Host "localhost"
		Port "2003"
		Protocol "tcp"
		LogSendErrors true
		StoreRates true
		AlwaysAppendDS false
		EscapeCharacter "_"
	</Node>
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
fi
}

install_graphite(){
apt-get install -yq postgresql libpq-dev python-psycopg2 apache2 libapache2-mod-wsgi
apt-get install -yq graphite-web graphite-carbon
}

configuration(){
GRAPHITE=/etc/graphite/local_settings.py
if ! [ -f /etc/apache2/sites-available/apache2-graphite.conf ]; then
  a2dissite 000-default
	cp /usr/share/graphite-web/apache2-graphite.conf /etc/apache2/sites-available
  a2ensite apache2-graphite
fi
sudo -u postgres psql <<EOF
CREATE USER graphite WITH PASSWORD 'uiuclug';
CREATE DATABASE graphite WITH OWNER graphite;
EOF
sed -i '/DATABASES = {/,/^}/d' $GRAPHITE
grep -q "^TIME_ZONE = 'America/Chicago'" $GRAPHITE || 
	echo "TIME_ZONE = 'America/Chicago'" >> $GRAPHITE
grep -q "^USE_REMOTE_USER_AUTHENTICATION = True" $GRAPHITE ||
	 echo "USE_REMOTE_USER_AUTHENTICATION = True" >> $GRAPHITE
grep -q "^SECRET_KEY = 'uiuclug'" $GRAPHITE || echo "SECRET_KEY = 'uiuclug'" >> $GRAPHITE

grep -q "^DATABASES = {" $GRAPHITE || cat <<EOF >> $GRAPHITE
DATABASES = {
    'default': {
        'NAME': 'graphite',
        'ENGINE': 'django.db.backends.postgresql_psycopg2',
        'USER': 'graphite',
        'PASSWORD': 'uiuclug',
        'HOST': '127.0.0.1',
        'PORT': ''
    }
}
EOF

grep -q "^ENABLE_LOGROTATION = True" /etc/carbon/carbon.conf || sed -i '/^ENABLE_LOGROTATION/s/False/True/' /etc/carbon/carbon.conf
grep -q "^CARBON_CACHE_ENABLED=true" /etc/default/graphite-carbon || sed -i '/^CARBON_CACHE_ENABLED/s/false/true/' /etc/default/graphite-carbon

cat <<EOF > /etc/carbon/storage-schemas.conf
# Schema definitions for Whisper files. Entries are scanned in order,
# and first match wins. This file is scanned for changes every 60 seconds.
#
#  [name]
#  pattern = regex
#  retentions = timePerPoint:timeToStore, timePerPoint:timeToStore, ...

# Carbon's internal metrics. This entry should match what is specified in
# CARBON_METRIC_PREFIX and CARBON_METRIC_INTERVAL settings
[carbon]
pattern = ^carbon\.
retentions = 60:90d


[default]
pattern = .*
retentions = 5s:30d,1m:60d,5m:1y,10m:5y
EOF

/usr/bin/expect <<EOF
spawn /usr/bin/graphite-manage syncdb
expect "Would you like to create one now?"
send "yes\n"
expect "Username"
send "admin\n"
expect "Email address:"
send "addr@company.com\n"
expect "Password:"
send "uiuclug\n"
expect "Password (again):"
send "uiuclug\n"
expect eof
EOF
}

services(){
service collectd restart
service carbon-cache start
service apache2 reload
}

install_dependencies "1.)"
install_collectd "2.)"
install_graphite "3.)"
configuration "4.)"
services "5.)"

echo
