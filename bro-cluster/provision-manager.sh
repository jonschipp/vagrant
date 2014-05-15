HOME=/home/vagrant

# Add repo for Google Perftools
sudo add-apt-repository ppa:agent-8131/ppa

# Install dependencies
sudo apt-get update
sudo apt-get -y install cmake make gcc g++ flex bison \
	libpcap-dev libssl-dev python-dev swig zlib1g-dev libmagic-dev

# Install extras
sudo apt-get -y install git libgeoip-dev gawk sendmail curl tcpreplay
#ipsumdump (no package), libgoogle-perftools-dev
wget --progress=dot:mega http://geolite.maxmind.com/download/geoip/database/GeoLiteCity.dat.gz
gunzip GeoLiteCity.dat.gz
sudo mv GeoLiteCity.dat /usr/share/GeoIP/GeoIPCity.dat

# Install latest Bro
git clone --recursive git://git.bro.org/bro
cd bro
./configure
make && sudo make install && make install-aux

cd $HOME

# Make Bro binaries accessible by re-setting the PATH
echo 'export PATH=/usr/local/bro/bin:$PATH' | sudo tee -a /etc/profile.d/bro.sh

# Bro uses this key to configure the nodes
sudo mv ~/.ssh/id_rsa /root/.ssh/id_rsa
sudo chmod 400 /root/.ssh/id_rsa

# Copy Bro configuration
sudo mv node.cfg /usr/local/bro/etc/node.cfg

# Configure
# broctl install && broctl check && broctl start
