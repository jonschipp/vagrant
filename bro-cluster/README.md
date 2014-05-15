Bro-Cluster
===========

````
$ vagrant up
```

will provision 3 machines:
 * 1 Bro Manager
 * 2 Bro Worker Nodes

Once provisioned, connect to the manager node, and then issue the following commands to start up the cluster:
```
$ vagrant ssh manager
```
```
$ sudo su -
$ ssh -i .ssh/id_rsa root@10.2.2.20 (add to known_hosts then exit)
$ ssh -i .ssh/id_rsa root@10.2.2.30 (add to known_hosts then exit)
$ broctl install && broctl check && broctl start
```

Traffic seen on the 2 worker nodes will be available in the logging directory on the manager:
/usr/local/bro/logs/
