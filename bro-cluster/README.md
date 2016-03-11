Bro-Cluster
===========

````
$ vagrant up
```

will provision 3 machines:
 * 1 Bro Manager
 * 2 Bro Worker Nodes

You can install a particular version of Bro by setting the version number as an argument to
the provision script in the Vagrantfile. By default the latest upstream version is checked from git.
To download the stable release of Bro 2.4.1, modify args in the line with the version number, like so:
```
manager.vm.provision "shell", path: "provision-manager.sh", privileged: "true", args: "2.4.1"
```
Once provisioned, connect to the manager node, and then issue the following commands to start up the cluster:
```
$ vagrant ssh manager
$ sudo -i
$ broctl deploy
```

Traffic seen on the 2 worker nodes will be available in the logging directory on the manager:
/usr/local/bro/logs/
