Bro-Cluster
===========

$ vagrant up

will provision 3 machines:
 * 1 Bro Manager
 * 2 Bro Worker Nodes

Once provisioned, on the manager node, issue the following command to start up the cluster:
$ broctl install && broctl check && broctl start

Traffic seen on the 2 worker nodes will be available in the logging directory on the manager:
/usr/local/bro/logs/
