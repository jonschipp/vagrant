# Bro Sandbox - Bro Upstream Latest
#
# VERSION               0.0.1
FROM      ubuntu
MAINTAINER Jon Schipp <jonschipp@gmail.com>
RUN apt-get update
RUN apt-get install -y git build-essential cmake make gcc g++ flex bison libpcap-dev libgeoip-dev libssl-dev python-dev zlib1g-dev libmagic-dev swig2.0 wget
RUN adduser --disabled-password --gecos "" demo
RUN su -l -c 'git clone --recursive git://git.bro.org/bro && cd bro && ./configure && make' demo
RUN cd /home/demo/bro && make install
RUN echo "PATH=$PATH:/usr/local/bro/bin/" > /etc/profile.d/bro.sh && chmod 555 /etc/profile.d/bro.sh
