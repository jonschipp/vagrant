#!/bin/bash
# Run once on first boot

touch /tmp/ran.provision.$(date +"%d-%m-%Y").shell

apt-get update
apt-get install build-essential
