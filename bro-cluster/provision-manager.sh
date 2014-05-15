HOME=/home/vagrant
ROOT=/root
BROPATH=/usr/local/bro

function die {
    echo $*
    exit 1
}

function configure_ssh {
    # Bro uses this key to configure the nodes
    if [ ! -d $ROOT/.ssh ]; then
	mkdir $ROOT/.ssh
	chown root:root $ROOT/.ssh
	chmod 600 $ROOT/.ssh
    fi

    if [ -f $ROOT/.ssh/id_rsa ]; then
	mv $HOME/.ssh/id_rsa $ROOT/.ssh/id_rsa
	chmod 400 $ROOT/.ssh/id_rsa
    fi
}

function configure_bro {
    if [ ! -e /bro ]; then
        ln -s /usr/local/bro /bro
    fi
    if [ ! -e /bro/site ]; then
        (cd /bro ; sudo ln -s share/bro/site . )
    fi
    # Copy Bro configuration
    if [ -e $HOME/node.cfg ]; then
	mv $HOME/node.cfg $BROPATH/etc/node.cfg
    fi
    # Make Bro binaries accessible by re-setting the PATH
    if [ ! -f /etc/profile.d/bro.sh ]; then
	echo 'export PATH=/usr/local/bro/bin:$PATH' | sudo tee -a /etc/profile.d/bro.sh
    fi
}

function install_dependencies {
    # Add repo for Google Perftools
    add-apt-repository ppa:agent-8131/ppa

    # Install dependencies
    apt-get update
    apt-get -y install cmake make gcc g++ flex bison \
    	libpcap-dev libssl-dev python-dev swig zlib1g-dev libmagic-dev
}

function install_extras {
    # Install extras
    apt-get -y install git libgeoip-dev gawk sendmail curl tcpreplay
    #ipsumdump (no package), libgoogle-perftools-dev

    if [ ! -f /usr/share/GeoIP/GeoIPCity.dat ]; then
    	wget --progress=dot:mega http://geolite.maxmind.com/download/geoip/database/GeoLiteCity.dat.gz
    	gunzip GeoLiteCity.dat.gz
    	mv GeoLiteCity.dat /usr/share/GeoIP/GeoIPCity.dat
    fi
}

function install_latest_bro {
    # Install latest Bro
    if [ ! -d /usr/local/bro ]; then
    	git clone --recursive git://git.bro.org/bro
    	cd bro
    	./configure || die "Configure failed!"
    	make || die "Build failed!"
    	make install && make install-aux || die "Install failed!"
    fi
}

function install_bro {
    if [ -d /usr/local/bro ] && [ "$(bro --version 2>&1 | grep -o '[0-9]\.[0-9]')" == "$VERSION" ];
    then
        echo "Bro already installed"
        return
    fi
    if [ ! -e bro-${VERSION}.tar.gz ] ; then
        echo "Downloading bro"
        wget -c http://www.bro.org/downloads/release/bro-${VERSION}.tar.gz --progress=dot:mega
    fi
    if [ ! -e bro-${VERSION} ] ; then
        echo "Untarring bro"
        tar xzf bro-${VERSION}.tar.gz
    fi
    cd bro-${VERSION}
    ./configure || die "Configure failed!"
    make || die "Build failed!"
    make install || die "Install failed!"

}

cd $HOME

install_dependencies
install_extras

if [[ $1 == "latest" ]]; then
	install_latest_bro
elif [[ $1 =~ [0-9]\.[0-9] ]]; then
	VERSION=$1
	install_bro
else
	install_latest_bro
fi

configure_ssh
configure_bro

exit 0
