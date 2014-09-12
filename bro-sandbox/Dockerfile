# Bro Sandbox - Bro Upstream Latest
#
# VERSION               1.0.1
FROM      ubuntu
MAINTAINER Jon Schipp <jonschipp@gmail.com>
RUN apt-get update
RUN apt-get install -y git build-essential cmake make gcc g++ flex bison libpcap-dev libgeoip-dev libssl-dev python-dev zlib1g-dev libmagic-dev swig2.0 wget
RUN apt-get install -y gawk
RUN adduser --disabled-password --gecos "" demo
RUN su -l -c 'git clone --recursive git://git.bro.org/bro && cd bro && ./configure && make' demo
RUN cd /home/demo/bro && make install
RUN echo "PATH=$PATH:/usr/local/bro/bin/" > /etc/profile.d/bro.sh && chmod 555 /etc/profile.d/bro.sh
RUN echo "export TMOUT=1800; readonly TMOUT" > /etc/profile.d/timeout.sh && chmod 555 /etc/profile.d/timeout.sh
RUN su -l -c 'ln -s /exercises exercises' demo

# DANGEROUS: Comment lines below if you would NOT like the user to be able to run Bro
# on an interface or use features of broctl (Possibility to break out of container).
# Allowed by default because people like to teach Bro like this.
RUN echo "demo ALL=(root) NOPASSWD:/usr/local/bro/bin/bro" > /etc/sudoers.d/bro
RUN echo "demo ALL=(root) NOPASSWD:/usr/local/bro/bin/broctl" >> /etc/sudoers.d/bro
RUN chmod 0440 /etc/sudoers.d/bro && chown root:root /etc/sudoers.d/bro
RUN echo "alias broctl='sudo /usr/local/bro/bin/broctl'" >> /etc/profile.d/bro.sh
RUN echo "alias bro='sudo /usr/local/bro/bin/bro'" >> /etc/profile.d/bro.sh
