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
To download the stable release of Bro 2.2, modify the line to look like the folowing:
```
manager.vm.provision "shell", path: "provision-manager.sh", privileged: "true", args: "2.2"
```
Once provisioned, connect to the manager node, and then issue the following commands to start up the cluster:
```
$ vagrant ssh manager
```
```
$ sudo su -
$ ssh -i .ssh/id_rsa root@10.1.1.20 (add to known_hosts then exit)
$ ssh -i .ssh/id_rsa root@10.1.1.30 (add to known_hosts then exit)
$ broctl install && broctl check && broctl start
```

Traffic seen on the 2 worker nodes will be available in the logging directory on the manager:
/usr/local/bro/logs/
