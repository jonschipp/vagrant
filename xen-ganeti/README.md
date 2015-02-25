Ganeti
===========

```
$ vagrant up
```

will provision two Ubuntu Trusty VM's for testing, playing, and developing with
 * Xen w/ Ganeti (PV virtualization only)

*Note:*  Adjust memory `--memory` in Vagrantfile if necessary, set to 4GB per node.

```
$ vagrant up
$ vagrant ssh node1
# Initialize cluster
$ gnt-cluster init --enabled-hypervisors=xen-pvm --hypervisor-parameters xen-pvm:xen_cmd=xl --vg-name ganeti --nic-parameters link=xenbr0 \
--master-netdev xenbr0 --secondary-ip 192.168.1.10 --no-ssh-init xen-cluster.test
# Add node2 to cluster
$ gnt-node add -v -d --no-ssh-key-check --master-capable=yes --vm-capable=yes --secondary-ip 192.168.1.20 xen-node2.test
# Test cluster
$ /usr/lib/ganeti/tools/burnin -v -d -o debootstrap+default --disk-size=1024m --mem-size=128m -p instance{1..3}
```
