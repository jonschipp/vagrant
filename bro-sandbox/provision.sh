#!/bin/bash
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 36A1D7869245C8950F966E92D8576A8BA88D21E9
sudo sh -c "echo deb http://get.docker.io/ubuntu docker main > /etc/apt/sources.list.d/docker.list"
sudo apt-get update
sudo apt-get -y install lxc-docker expect

cat > Dockerfile <<EOF
# Bro Sandbox
#
# VERSION               0.0.1
FROM      ubuntu
MAINTAINER Jon Schipp <jonschipp@gmail.com>
RUN apt-get update
RUN apt-get install -y build-essential cmake make gcc g++ flex bison libpcap-dev libgeoip-dev libssl-dev python-dev zlib1g-dev libmagic-dev swig2.0 wget
RUN adduser --disabled-password --gecos "" demo
RUN su -l -c 'wget http://www.bro.org/downloads/release/bro-2.2.tar.gz && tar -xvzf bro-2.2.tar.gz && cd bro-2.2 && ./configure && make' demo
RUN cd /home/demo/bro-2.2 && make install
RUN echo "PATH=$PATH:/usr/local/bro/bin/" > /etc/profile.d/bro.sh && chmod 555 /etc/profile.d/bro.sh
RUN echo > /etc/update-motd.d/10-help-text && echo > /etc/update-motd.d/00-header
EOF

sudo docker build -t sandbox - < Dockerfile
#sudo docker commit $(docker ps -a -q | head -n 1) sandbox

cat > /usr/local/bin/sandbox <<EOF
#!/bin/sh
exec sudo docker run -t -h bro -c 1 -m 100m -i --rm=true sandbox /bin/bash -c 'su - demo'
EOF

sudo cat > /etc/sudoers.d/sandbox <<EOF
Cmnd_Alias SANDBOX = /usr/bin/docker
demo ALL=(root) NOPASSWD: SANDBOX
EOF

sudo chmod 0440 /etc/sudoers.d/sandbox
sudo chmod a+x /usr/local/bin/sandbox
sudo echo /usr/local/bin/sandbox >> /etc/shells
sudo adduser --disabled-login --gecos "" --shell /usr/local/bin/sandbox demo

/usr/bin/expect <<EOF
spawn /usr/bin/passwd demo
expect "password:"
send "demo\n"
expect "password:"
send "demo\n"
expect eof
EOF
