#!/bin/bash
# Run once on first boot

touch /tmp/ran.provision.$(date +"%d-%m-%Y").shell

# Disable firewall and network ACL's and allow ssh connections
sudo iptables -F
sudo ufw disable
sudo ufw allow 22

/usr/bin/expect <<EOF
spawn /usr/bin/sudo /usr/sbin/ufw enable
expect "Proceed with operation"
send "y\n"
expect eof
EOF

sudo rm /etc/udev/rules.d/70-persistent-net.rules

yes | mkfs -t ext4 /dev/sdb
mount /dev/sdb /nsm

cat <<EOF >> /etc/fstab
# Store NSM data on other drive
/dev/sdb	/nsm		ext4			  auto,rw,nosuid,noexec   0	  0
EOF
