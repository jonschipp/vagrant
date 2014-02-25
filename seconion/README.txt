###########################
# Getting up and running: #
###########################

##############
# Clone repo #
##############

``git clone http://github.com/jonschipp/vagrant''

# Simple way:

# Create directory for vagrant project
1.) ``mkdir -p ~/vagrant/projects/seconion-server && ~/vagrant/projects/seconion-server''
# Copy Vagrantfile and provision.sh from repo to project directory
2.) ``cp Vagrantfile provision.sh ~/vagrant/projects/seconion-server/''
# Bring up machine
3.) ``vagrant up --no-provision''
# Provision the machine after it has booted
4.) ``vagrant provision --provision-with shell''
# Reload the ready machine
6.) ``vagrant reload --no-provision''
# Use
7.) ``vagrant ssh''

# Other way:

# Download vagrant box and import it
1.) ``vagrant box add seconion1204 http://jonschipp.com/vm/seconion1204.box --provider virtualbox''
# Create directory for project
2.) ``mkdir -p ~/vagrant/projects/seconion-server && cd ~/vagrant/projects/seconion-server''
# Copy Vagrantfile and provision.sh to the directory above
3.) ``cp Vagrantfile provision.sh ~/vagrant/projects/seconion-server/''
# Bring up the machine
4.) ``vagrant up --no-provision''
# Provision the machine after it has booted
5.) ``vagrant provision --provision-with shell''
# Reload the ready machine
6.) ``vagrant reload --no-provision''
# Use
7.) ``vagrant ssh''
